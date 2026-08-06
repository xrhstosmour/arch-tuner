#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
FIREWALL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$FIREWALL_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$FIREWALL_SCRIPT_DIRECTORY/../functions/services.sh"

# Initialize a flag indicating if a firewall change has been made.
firewall_changes_made=1

# Install needed firewall packages.
install_packages "iptables" "$AUR_PACKAGE_MANAGER" "Installing needed firewall packages..."

# Install firewall.
install_packages "ufw" "$AUR_PACKAGE_MANAGER" "Installing firewall..."

# Set firewall.
start_service "ufw" "Starting firewall..."

# Enable firewall.
enable_service "ufw" "Enabling firewall..."

# Check if default deny rules are set and if not set them.
if ! sudo ufw status verbose | grep -q 'Default: deny (incoming), deny (outgoing), deny (routed)'; then
    log_info "Denying all incoming and outgoing connections."
    sudo ufw default deny incoming
    sudo ufw default deny outgoing

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Allow SSH on port 2222/tcp (covers both IPv4 and IPv6).
if ! sudo ufw status | grep -q '2222/tcp'; then
    log_info "Allowing SSH (2222/TCP) connections."
    sudo ufw allow in 2222/tcp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Allow inbound HTTP (80/tcp) for the reverse proxy (Traefik). Plain `ufw
# status` prints inbound rules as "ALLOW ... Anywhere" and outbound rules as
# "ALLOW OUT ... Anywhere", with no "IN" marker, so the check must require
# "Anywhere" directly after "ALLOW" to avoid matching the outbound rule below.
if ! sudo ufw status | grep -qE '80/tcp[[:space:]]+ALLOW[[:space:]]+Anywhere'; then
    log_info "Allowing inbound HTTP (80/TCP) connections."
    sudo ufw allow in 80/tcp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Allow inbound HTTPS (443/tcp) for the reverse proxy (Traefik), fronting
# Netbird's dashboard, management, signal and relay, and Authelia. Same
# direction-aware check as the HTTP rule above.
if ! sudo ufw status | grep -qE '443/tcp[[:space:]]+ALLOW[[:space:]]+Anywhere'; then
    log_info "Allowing inbound HTTPS (443/TCP) connections."
    sudo ufw allow in 443/tcp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Allow inbound Netbird Coturn STUN/TURN (3478/udp). It cannot be proxied
# through the reverse proxy and must stay directly reachable.
if ! sudo ufw status | grep -q '3478/udp'; then
    log_info "Allowing Netbird Coturn (3478/UDP) connections."
    sudo ufw allow in 3478/udp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Allow outbound DNS (53/tcp and 53/udp).
if ! sudo ufw status | grep -q '53/tcp'; then
    log_info "Allowing DNS (53/TCP) connections."
    sudo ufw allow out 53/tcp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi
if ! sudo ufw status | grep -q '53/udp'; then
    log_info "Allowing DNS (53/UDP) connections."
    sudo ufw allow out 53/udp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Allow outbound HTTP (80/tcp). Direction-aware check, an inbound 80/tcp rule
# now exists above and would otherwise satisfy a plain "80/tcp" match.
if ! sudo ufw status | grep -qE '80/tcp[[:space:]]+ALLOW OUT'; then
    log_info "Allowing HTTP (80/TCP) connections."
    sudo ufw allow out 80/tcp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Allow outbound HTTPS (443/tcp). Direction-aware check, same reason as HTTP.
if ! sudo ufw status | grep -qE '443/tcp[[:space:]]+ALLOW OUT'; then
    log_info "Allowing HTTPS (443/TCP) connections."
    sudo ufw allow out 443/tcp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Allow outbound NTP (123/udp).
if ! sudo ufw status | grep -q '123/udp'; then
    log_info "Allowing NTP (123/UDP) connections."
    sudo ufw allow out 123/udp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# change_configuration does not apply here, it replaces or appends a single
# key's value, this needs a multi-line rule inserted before the COMMIT line,
# appending after COMMIT would break the ufw rules file.
# Check if ICMPv6 rule exists and if not add it.
if ! grep -q 'ufw6-before-output -p ipv6-icmp -j ACCEPT' /etc/ufw/before6.rules; then
    log_info "Allowing ICMPv6 connections."

    # Add the rule before the COMMIT line.
    sudo sed -i '/COMMIT/ i # Allow outbound ipv6-icmp.\n-A ufw6-before-output -p ipv6-icmp -j ACCEPT' /etc/ufw/before6.rules

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Restarting firewall to apply new rules.
if [ $firewall_changes_made -eq 0 ]; then
    log_info "Restarting firewall."
    sudo ufw reload
fi

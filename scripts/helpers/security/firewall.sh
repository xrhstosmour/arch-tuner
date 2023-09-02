#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
FIREWALL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$FIREWALL_SCRIPT_DIRECTORY/../functions.sh"

# Initialize a flag indicating if a firewall change has been made.
firewall_changes_made=1

# Install needed firewall packages.
install_packages "iptables" "$AUR_PACKAGE_MANAGER" "Installing needed firewall packages..."

# Install firewall.
install_packages "ufw" "$AUR_PACKAGE_MANAGER" "Installing firewall..."

# Setting firewall.
start_service "ufw" "Starting firewall..."

# Enabling firewall.
enable_service "ufw" "Enabling firewall..."

# Check if default deny rules are set and if not set them.
if ! sudo ufw status verbose | grep -q 'Default: deny (incoming), deny (outgoing), deny (routed)'; then
    log_info "Denying all incoming and outgoing connections..."
    sudo ufw default deny incoming
    sudo ufw default deny outgoing

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Check if DHCPv6 rule exists and if not add it.
if ! sudo ufw status | grep -q '546/udp (v6)'; then
    log_info "Allowing DHCPv6 (546/UDP) connections..."
    sudo ufw allow out to any port 546 proto udp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Check if ICMPv6 rule exists and if not add it.
if ! grep -q 'ufw6-before-output -p ipv6-icmp -j ACCEPT' /etc/ufw/before6.rules; then
    log_info "Allowing ICMPv6 connections..."

    # Add the rule before the COMMIT line.
    sudo sed -i '/COMMIT/ i # Allow outbound ipv6-icmp.\n-A ufw6-before-output -p ipv6-icmp -j ACCEPT' /etc/ufw/before6.rules

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Check if HTTP and HTTPS rules exist and if not add them.
if ! sudo ufw status | grep -q '80/tcp'; then
    log_info "Allowing HTTP (80/TCP) connections..."
    sudo ufw allow out to any port 80 proto tcp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi
if ! sudo ufw status | grep -q '443/tcp'; then
    log_info "Allowing HTTPS (443/TCP) connections..."
    sudo ufw allow out to any port 443 proto tcp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Check if DNS rule exists and if not add it.
if ! sudo ufw status | grep -q '53/tcp'; then
    log_info "Allowing DNS (53/TCP) connections..."
    sudo ufw allow out to any port 53 proto tcp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi
if ! sudo ufw status | grep -q '53/udp'; then
    log_info "Allowing DNS (53/UDP) connections..."
    sudo ufw allow out to any port 53 proto udp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Check if DHCP client rule exists and if not add it.
if ! sudo ufw status | grep -q '67/udp'; then
    log_info "Allowing DHCP (67/UDP) connections..."
    sudo ufw allow out to any port 67 proto udp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi
if ! sudo ufw status | grep -q '68/udp'; then
    log_info "Allowing DHCP (68/UDP) connections..."
    sudo ufw allow out to any port 68 proto udp

    # Set the firewall_changes_made flag to 0 (true).
    firewall_changes_made=0
fi

# Restarting firewall to apply new rules.
if [ $firewall_changes_made -eq 0 ]; then
    log_info "Restarting firewall..."
    sudo ufw reload
fi

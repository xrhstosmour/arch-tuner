#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DNS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DNS_SCRIPT_DIRECTORY/../functions/services.sh"
source "$DNS_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Initialize a flag to track whether a change was made.
dns_changes_made=1

# Constant variables for keeping the resolved configuration.
RESOLVED_CONFIGURATION="/etc/systemd/resolved.conf"

# Set 'DNSSEC' to 'yes', whether the line is missing, commented out, or set
# to something else.
if ! grep -q '^DNSSEC=yes' "$RESOLVED_CONFIGURATION"; then
    change_configuration "DNSSEC=" "yes" "$RESOLVED_CONFIGURATION"

    # Set the dns_changes_made flag to 0 (true).
    dns_changes_made=0
fi

# Set 'DNSOverTLS' to 'yes', whether the line is missing, commented out, or
# set to something else.
if ! grep -q '^DNSOverTLS=yes' "$RESOLVED_CONFIGURATION"; then
    change_configuration "DNSOverTLS=" "yes" "$RESOLVED_CONFIGURATION"

    # Set the dns_changes_made flag to 0 (true).
    dns_changes_made=0
fi

# If a change was made, restart the 'systemd-resolved' service to apply the changes
if [ $dns_changes_made -eq 0 ]; then
    log_info "Enabling DNSSEC and DNSOverTLS..."
    stop_service "systemd-resolved" "Stopping DNS service..."
    start_service "systemd-resolved" "Starting DNS service..."
fi

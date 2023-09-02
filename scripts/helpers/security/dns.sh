#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DNS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DNS_SCRIPT_DIRECTORY/../functions.sh"

# Constant variables for keeping the resolved configuration.
RESOLVED_CONFIGURATION="/etc/systemd/resolved.conf"

# Initialize a variable to track whether a change was made.
dns_changes_made=1

# Check if the 'DNSSEC' line already exists in the 'resolved.conf' file.
if grep -q '^DNSSEC=' "$RESOLVED_CONFIGURATION"; then

    # Check if 'DNSSEC' is set to 'yes', if not, replace it with 'DNSSEC=yes'
    if ! grep -q '^DNSSEC=yes' "$RESOLVED_CONFIGURATION"; then
        sudo sed -i 's/^DNSSEC=.*/DNSSEC=yes/' "$RESOLVED_CONFIGURATION"

        # Set the dns_changes_made flag to 0 (true).
        dns_changes_made=0
    fi
else

    # If the 'DNSSEC' line doesn't exist, add 'DNSSEC=yes' to the end of the file
    echo 'DNSSEC=yes' | sudo tee -a "$RESOLVED_CONFIGURATION" >/dev/null

    # Set the dns_changes_made flag to 0 (true).
    dns_changes_made=0
fi

# If a change was made, restart the 'systemd-resolved' service to apply the changes
if [ $dns_changes_made -eq 0 ]; then
    log_info "Enabling DNSSEC..."
    stop_service "systemd-resolved" "Stopping DNS service..."
    start_service "systemd-resolved" "Starting DNS service..."
fi

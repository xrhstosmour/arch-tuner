#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SYSTEMD_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SYSTEMD_SCRIPT_DIRECTORY/../functions/logs.sh"
source "$SYSTEMD_SCRIPT_DIRECTORY/../functions/services.sh"
source "$SYSTEMD_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variables for the systemd configuration paths.
# Docker is excluded, its namespace/kernel-module needs conflict with this drop-in; it is hardened via daemon.json instead.
SYSTEMD_SERVICE_NAMES=("sshd" "chronyd")
SYSTEMD_CONFIGURATION_TO_PASS="$SYSTEMD_SCRIPT_DIRECTORY/../../configurations/security/systemd/99-hardening"

# Flag to track if any changes were made. 1 = no change, 0 = change made.
systemd_changes_made=1

# Function to configure a specific service.
configure_service() {
    local service_name="$1"
    
    # Create the drop-in directory if it does not exist.
    local drop_in_directory="/etc/systemd/system/${service_name}.service.d/"
    if [ ! -d "$drop_in_directory" ]; then
        sudo mkdir -p "$drop_in_directory"
    fi
    
    # Copy the hardening configuration if it differs from the current one.
    local drop_in_file="$drop_in_directory/99-hardening.conf"
    are_files_the_same=$(compare_files "$drop_in_file" "$SYSTEMD_CONFIGURATION_TO_PASS")
    
    if [[ "$are_files_the_same" != "true" ]]; then
        sudo cp -f "$SYSTEMD_CONFIGURATION_TO_PASS" "$drop_in_file"
        systemd_changes_made=0
        log_success "${service_name} systemd drop-in applied."
    else
        log_info "${service_name} systemd drop-in already in place."
    fi
}

# Apply hardening to all services.
for service in "${SYSTEMD_SERVICE_NAMES[@]}"; do
    configure_service "$service"
done

# Reload systemd and restart services if any changes were made.
if [[ $systemd_changes_made -eq 0 ]]; then
    sudo systemctl daemon-reload
    
    for service in "${SYSTEMD_SERVICE_NAMES[@]}"; do
        log_info "Restarting ${service} service..."
        sudo systemctl restart "$service"
    done
else
    log_info "No systemd hardening was applied."
fi

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SSH_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SSH_SCRIPT_DIRECTORY/../functions/logs.sh"
source "$SSH_SCRIPT_DIRECTORY/../functions/services.sh"
source "$SSH_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variables for the SSH server configuration paths.
SSH_CONFIGURATION="/etc/ssh/sshd_config"
SSH_CONFIGURATION_TO_PASS="$SSH_SCRIPT_DIRECTORY/../../configurations/security/ssh/sshd_config"

# Stop the SSH service before modifying its configuration.
stop_service sshd

# Copy the hardened SSH configuration if it differs from the current one.
are_ssh_files_the_same=$(compare_files "$SSH_CONFIGURATION" "$SSH_CONFIGURATION_TO_PASS")

if [[ "$are_ssh_files_the_same" != "true" ]]; then
    sudo cp -f "$SSH_CONFIGURATION_TO_PASS" "$SSH_CONFIGURATION"
    log_success "SSH configuration updated."
else
    log_info "SSH configuration already up to date."
fi

# Start the SSH service.
start_service sshd

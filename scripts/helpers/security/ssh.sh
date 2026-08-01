#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SSH_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SSH_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$SSH_SCRIPT_DIRECTORY/../functions/services.sh"
source "$SSH_SCRIPT_DIRECTORY/../functions/logs.sh"
source "$SSH_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# SSH hardening helper

# Source sshd configuration
source_file="$SSH_SCRIPT_DIRECTORY/../../configurations/security/ssh/sshd_config"
target_file="/etc/ssh/sshd_config"

# Check if source file exists
if [ ! -f "$source_file" ]; then
    log_error "Source SSH configuration file not found: $source_file"
    exit 1
fi

# Compare and copy if different
compare_result=$(compare_files "$target_file" "$source_file")
if [ "$compare_result" = "false" ]; then
    log_info "SSH configuration differs from source. Copying..."
    mkdir -p "$(dirname "$target_file")"
    cp -f "$source_file" "$target_file"
    log_info "SSH configuration copied successfully."
else
    log_info "SSH configuration matches source. No changes needed."
fi

# Reload SSH service
start_service "sshd" "Restarting SSH service..."

log_info "SSH hardening completed successfully."

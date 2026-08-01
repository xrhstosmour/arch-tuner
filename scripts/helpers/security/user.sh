#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
USER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$USER_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$USER_SCRIPT_DIRECTORY/../functions/services.sh"
source "$USER_SCRIPT_DIRECTORY/../functions/logs.sh"
source "$USER_SCRIPT_DIRECTORY/../functions/ui.sh"

# User creation and SSH hardening helper

# Prompt user for username with default "admin"
username=$(prompt_user_input "Enter a username (default: admin)" "admin")

# Check if user exists
if id "$username" &>/dev/null; then
    log_info "User '$username' already exists."
else
    log_info "User '$username' does not exist. Creating user..."
    # Create user with home directory and add to wheel group
    sudo useradd -m -G wheel "$username"
    # Set initial password
    sudo passwd "$username"
    log_info "User '$username' created successfully."
fi

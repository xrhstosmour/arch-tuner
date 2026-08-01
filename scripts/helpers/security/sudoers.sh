#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SUDOERS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SUDOERS_SCRIPT_DIRECTORY/../functions/logs.sh"
source "$SUDOERS_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$SUDOERS_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variables for the sudoers configuration paths.
SUDOERS_CONFIGURATION="/etc/sudoers.d/99-hardening"
SUDOERS_CONFIGURATION_TO_PASS="$SUDOERS_SCRIPT_DIRECTORY/../../configurations/security/sudoers/99-hardening"

# Install the sudo package if not present.
install_packages "sudo" "$AUR_PACKAGE_MANAGER" "Installing sudo..."

# Copy the hardened sudoers configuration if it differs from the current one.
are_sudoers_files_the_same=$(compare_files "$SUDOERS_CONFIGURATION" "$SUDOERS_CONFIGURATION_TO_PASS")

if [[ "$are_sudoers_files_the_same" != "true" ]]; then
    sudo cp -f "$SUDOERS_CONFIGURATION_TO_PASS" "$SUDOERS_CONFIGURATION"
    sudo chmod 0440 "$SUDOERS_CONFIGURATION"
    log_success "Sudoers hardening applied."
else
    log_info "Sudoers hardening already in place."
fi

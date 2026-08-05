#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SYSCTL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SYSCTL_SCRIPT_DIRECTORY/../functions/logs.sh"
source "$SYSCTL_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variables for the sysctl configuration paths.
SYSCTL_CONFIGURATION="/etc/sysctl.d/99-hardening.conf"
SYSCTL_CONFIGURATION_TO_PASS="$SYSCTL_SCRIPT_DIRECTORY/../../configurations/security/sysctl/99-hardening.conf"

# Copy the hardened sysctl configuration if it differs from the current one.
are_sysctl_files_the_same=$(compare_files "$SYSCTL_CONFIGURATION" "$SYSCTL_CONFIGURATION_TO_PASS")

if [[ "$are_sysctl_files_the_same" != "true" ]]; then
    sudo cp -f "$SYSCTL_CONFIGURATION_TO_PASS" "$SYSCTL_CONFIGURATION"
    sudo sysctl --system
    log_success "Sysctl hardening applied."
else
    log_info "Sysctl hardening already in place."
fi
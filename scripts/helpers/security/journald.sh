#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
JOURNALD_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$JOURNALD_SCRIPT_DIRECTORY/../functions/logs.sh"
source "$JOURNALD_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variables for the journald configuration paths.
JOURNALD_CONFIGURATION="/etc/systemd/journald.conf"
JOURNALD_CONFIGURATION_TO_PASS="$JOURNALD_SCRIPT_DIRECTORY/../../configurations/security/journald/99-hardening.conf"

# Copy the hardened journald configuration if it differs from the current one.
are_journald_files_the_same=$(compare_files "$JOURNALD_CONFIGURATION" "$JOURNALD_CONFIGURATION_TO_PASS")

if [[ "$are_journald_files_the_same" != "true" ]]; then
    sudo cp -f "$JOURNALD_CONFIGURATION_TO_PASS" "$JOURNALD_CONFIGURATION"
    sudo systemctl restart systemd-journald
    log_success "Systemd journald configuration applied."
else
    log_info "Systemd journald configuration already in place."
fi

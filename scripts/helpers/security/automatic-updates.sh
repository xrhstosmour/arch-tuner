#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
AUTOMATIC_UPDATES_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$AUTOMATIC_UPDATES_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$AUTOMATIC_UPDATES_SCRIPT_DIRECTORY/../functions/services.sh"
source "$AUTOMATIC_UPDATES_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Install automatic updates packages.
install_packages "$AUTOMATIC_UPDATES_SCRIPT_DIRECTORY/../../packages/security/automatic-updates.txt" "$AUR_PACKAGE_MANAGER" "Installing automatic updates packages..."

# Copy systemd unit files if they differ from the existing ones.
SYSTEMD_SERVICE_SOURCE="$AUTOMATIC_UPDATES_SCRIPT_DIRECTORY/../../../systemd/arch-tuner-update.service"
SYSTEMD_SERVICE_TARGET="/etc/systemd/system/arch-tuner-update.service"
are_files_the_same=$(compare_files "$SYSTEMD_SERVICE_TARGET" "$SYSTEMD_SERVICE_SOURCE")
if [[ "$are_files_the_same" != "true" ]]; then
    sudo cp -f "$SYSTEMD_SERVICE_SOURCE" "$SYSTEMD_SERVICE_TARGET"
    log_info "Systemd service file copied."
fi

SYSTEMD_TIMER_SOURCE="$AUTOMATIC_UPDATES_SCRIPT_DIRECTORY/../../../systemd/arch-tuner-update.timer"
SYSTEMD_TIMER_TARGET="/etc/systemd/system/arch-tuner-update.timer"
are_timer_files_the_same=$(compare_files "$SYSTEMD_TIMER_TARGET" "$SYSTEMD_TIMER_SOURCE")
if [[ "$are_timer_files_the_same" != "true" ]]; then
    sudo cp -f "$SYSTEMD_TIMER_SOURCE" "$SYSTEMD_TIMER_TARGET"
    log_info "Systemd timer file copied."
fi

# Run daemon reload if any changes were made.
if [[ "$are_files_the_same" != "true" ]] || [[ "$are_timer_files_the_same" != "true" ]]; then
    log_info "Running systemd daemon-reload..."
    sudo systemctl daemon-reload
    log_info "Systemd daemon-reload completed."
fi

# Enable and start the timer.
enable_service "arch-tuner-update.timer"
start_service "arch-tuner-update.timer"
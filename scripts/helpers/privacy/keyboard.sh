#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
KEYBOARD_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$KEYBOARD_SCRIPT_DIRECTORY/../functions.sh"

# Constant variables for keystroke anonymization configuration.
KEYSTROKE_ANONYMIZATION_PACKAGE="kloak"
KEYSTROKE_ANONYMIZATION_CONFIGURATION="/etc/systemd/system/kloak.service"

# Install keystroke anonymization package.
install_packages "$KEYSTROKE_ANONYMIZATION_PACKAGE-git" "$AUR_PACKAGE_MANAGER" "Installing keystroke anonymization..."

# Create a systemd service to run keystroke anonymization at startup.
if [ ! -f "$KEYSTROKE_ANONYMIZATION_CONFIGURATION" ]; then
    log_info "Creating keystroke anonymization service..."
    echo "[Unit]
        Description=Keystroke anonymization service

        [Service]
        ExecStart=/usr/bin/$KEYSTROKE_ANONYMIZATION_PACKAGE

        [Install]
        WantedBy=multi-user.target" | sudo tee "$KEYSTROKE_ANONYMIZATION_CONFIGURATION"
fi

# Start and enable the service.
start_service "$KEYSTROKE_ANONYMIZATION_PACKAGE" "Starting $KEYSTROKE_ANONYMIZATION_PACKAGE service..."
enable_service "$KEYSTROKE_ANONYMIZATION_PACKAGE" "Enabling $KEYSTROKE_ANONYMIZATION_PACKAGE service..."

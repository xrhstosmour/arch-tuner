#!/bin/bash

# ! When enabling the service, every password input is wrong: https://github.com/vmonaco/kloak/issues/12.
# ! I do not know if it is related to the kloak, kloak-git or at adding the user to input group.

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
KEYBOARD_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$KEYBOARD_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$KEYBOARD_SCRIPT_DIRECTORY/../functions/services.sh"

# Constant variables for keystroke anonymization configuration.
KEYSTROKE_ANONYMIZATION_PACKAGE="kloak"
KEYSTROKE_ANONYMIZATION_CONFIGURATION="/etc/systemd/system/kloak.service"

# Constant variable containing the keystroke anonymization packages to install.
KEYSTROKE_ANONYMIZATION_PACKAGES="libevdev $KEYSTROKE_ANONYMIZATION_PACKAGE"

# Check if at least one keystroke anonymization package is not installed.
are_keystroke_anonymization_packages_installed=$(are_packages_installed "$KEYSTROKE_ANONYMIZATION_PACKAGES" "$AUR_PACKAGE_MANAGER")
if [ "$are_keystroke_anonymization_packages_installed" = "false" ]; then
    log_info "Installing keystroke anonymization packages..."

    # Install security packages.
    install_packages "$KEYSTROKE_ANONYMIZATION_PACKAGES" "$AUR_PACKAGE_MANAGER"
fi

# Create a systemd service to run keystroke anonymization at startup.
if [ ! -f "$KEYSTROKE_ANONYMIZATION_CONFIGURATION" ]; then
    log_info "Creating keystroke anonymization service..."
    echo "[Unit]
        Description=Keystroke anonymization service

        [Service]
        ExecStart=/usr/bin/$KEYSTROKE_ANONYMIZATION_PACKAGE

        [Install]
        WantedBy=multi-user.target" | sudo tee "$KEYSTROKE_ANONYMIZATION_CONFIGURATION" >/dev/null
fi

# Add the user to the input group.
if ! groups $USER | grep -q '\binput\b'; then
    log_info "Adding $USER to the input group..."
    sudo usermod -aG input $USER
fi

# Start and enable the service.
start_service "$KEYSTROKE_ANONYMIZATION_PACKAGE" "Starting $KEYSTROKE_ANONYMIZATION_PACKAGE service..."
enable_service "$KEYSTROKE_ANONYMIZATION_PACKAGE" "Enabling $KEYSTROKE_ANONYMIZATION_PACKAGE service..."

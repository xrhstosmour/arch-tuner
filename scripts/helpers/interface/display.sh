#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DISPLAY_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DISPLAY_SCRIPT_DIRECTORY/../functions.sh"

# Constant variables for display manager configuration.
DISPLAY_MANAGER_PACKAGE="ly"
DISPLAY_MANAGER_CONFIGURATION="/etc/ly/config.ini"
DISPLAY_MANAGER_BLANK_PASSWORD="blank_password"
DISPLAY_MANAGER_BLANK_PASSWORD_TRUE="blank_password = true"

# Install display manager.
install_packages "$DISPLAY_MANAGER_PACKAGE-git" "$AUR_PACKAGE_MANAGER" "Installing display manager..."

# Enable display manager.
enable_service "$DISPLAY_MANAGER_PACKAGE" "Enabling display manager..."

# Uncomment any line that contains 'blank_password'.
sudo sed -i "/#.*$DISPLAY_MANAGER_BLANK_PASSWORD/s/^#//" "$DISPLAY_MANAGER_CONFIGURATION"

# Check if the setting already exists and if it matches the desired value.
if grep -q "$DISPLAY_MANAGER_BLANK_PASSWORD" "$DISPLAY_MANAGER_CONFIGURATION"; then
    if ! grep -q "^$DISPLAY_MANAGER_BLANK_PASSWORD_TRUE" "$DISPLAY_MANAGER_CONFIGURATION"; then
        log_info "Setting display manager blank password to true..."
        sudo sed -i "/^$DISPLAY_MANAGER_BLANK_PASSWORD/c\\$DISPLAY_MANAGER_BLANK_PASSWORD_TRUE" "$DISPLAY_MANAGER_CONFIGURATION"
    fi
else
    # If the setting doesn't exist at all, append it to the configuration file.
    log_info "Adding display manager blank password true..."
    echo "$DISPLAY_MANAGER_BLANK_PASSWORD_TRUE" | sudo tee -a "$DISPLAY_MANAGER_CONFIGURATION" >/dev/null
fi

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
LY_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$LY_SCRIPT_DIRECTORY/../../functions/packages.sh"
source "$LY_SCRIPT_DIRECTORY/../../functions/services.sh"

# Constant variables for ly display manager configuration.
LY_PACKAGE="ly"
DISPLAY_MANAGER_SERVICE="/etc/systemd/system/display-manager.service"
LY_CONFIGURATION_FILE="/etc/ly/config.ini"
declare -a LY_CONFIGURATIONS=("blank_password = true" "wayland_specifier = true" "load = true" "clock = %c")

# Check if another display manager is already enabled.
if [ -L "$DISPLAY_MANAGER_SERVICE" ]; then
    existing_display_manager=$(readlink "$DISPLAY_MANAGER_SERVICE")
    log_info "Disabling $existing_display_manager display manager..."
    sudo systemctl disable "$existing_display_manager"
fi

# Install and enable ly display manager
install_packages "$LY_PACKAGE" "$AUR_PACKAGE_MANAGER" "Installing ly display manager..."
enable_service "$LY_PACKAGE" "Enabling ly display manager..."

# Uncomment lines containing the above constants up to the equal sign.
for ly_configuration in "${LY_CONFIGURATIONS[@]}"; do

    # Extract the part of the configuration, up to the equal sign.
    ly_configuration_up_to_eqaul=$(echo "$ly_configuration" | sed 's/^\(.*=\).*/\1/')

    # Uncomment the line.
    sudo sed -i "/^#\s*$ly_configuration_up_to_eqaul/c\\$ly_configuration" "$LY_CONFIGURATION_FILE"

    # If the configuration exists proceed.
    if grep -q "^$ly_configuration_up_to_eqaul" "$LY_CONFIGURATION_FILE"; then

        # Update the setting if it's different.
        if ! grep -q "^$ly_configuration" "$LY_CONFIGURATION_FILE"; then
            log_info "Setting $ly_configuration..."
            sudo sed -i "/^$ly_configuration_up_to_eqaul/c\\$ly_configuration" "$LY_CONFIGURATION_FILE"
        fi
    else

        # Append the setting if it doesn't exist.
        log_info "Adding $ly_configuration..."
        echo "$ly_configuration" | sudo tee -a "$LY_CONFIGURATION_FILE" >/dev/null
    fi
done

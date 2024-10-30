#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
BLUETOOTH_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$BLUETOOTH_SCRIPT_DIRECTORY/../../functions/packages.sh"
source "$BLUETOOTH_SCRIPT_DIRECTORY/../../functions/services.sh"
source "$BLUETOOTH_SCRIPT_DIRECTORY/../../functions/filesystem.sh"

# Constant variables for bluetooth configuration.
BLUETOOTH_PACKAGE="bluez"
BLUETOOTH_SERVICE="bluetooth"
BLUETOOTH_CONFIGURATION="/etc/bluetooth/main.conf"
BLUETOOTH_AUTOENABLE_CONFIGURATION="AutoEnable="

# Check if the needed bluetooth package is installed.
is_bluetooth_package_installed=$(are_packages_installed "$BLUETOOTH_PACKAGE" "$AUR_PACKAGE_MANAGER")
if [ "$is_bluetooth_package_installed" = "true" ]; then
    log_info "Configuring $BLUETOOTH_SERVICE service..."

    # Enable and start bluetooth services.
    start_service "$BLUETOOTH_SERVICE" "Starting $BLUETOOTH_SERVICE service..."
    enable_service "$BLUETOOTH_SERVICE" "Enabling $BLUETOOTH_SERVICE service..."

    # Ensure `AutoEnable` is set to `true`.
    change_configuration "$BLUETOOTH_AUTOENABLE_CONFIGURATION" "true" "$BLUETOOTH_CONFIGURATION"

    # Restart bluetooth service to apply changes.
    stop_service "$BLUETOOTH_SERVICE" "Stopping $BLUETOOTH_SERVICE service..."
    start_service "$BLUETOOTH_SERVICE" "Starting $BLUETOOTH_SERVICE service..."
fi

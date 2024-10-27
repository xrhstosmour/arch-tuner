#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
USB_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$USB_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$USB_SCRIPT_DIRECTORY/../functions/services.sh"

# Constant variable for keeping the USB configuration.
USB_CONFIGURATION="/etc/usbguard/rules.conf"

# Initialize a flag indicating if a USB port protection change has been made.
usb_chnages_made=1

# Install USB port protection.
install_packages "usbguard" "$AUR_PACKAGE_MANAGER" "Installing USB port protection..."

# Enable the USB port protection service.
enable_service "usbguard" "Enabling USB port protection..."

# TODO: Generate abbreviations to allow connected devices permantly and for now.
# Generate an initial policy, if none exists and allow the already connected devices.
# ? We will use the default police which allows only the already connected devices.
# ? In case you want to allow permanently a device:
# ? 1. Connect the device.
# ? 2. Run 'sudo usbguard list-devices'.
# ? 3. Find the DEVICE_ID of the device you want to allow.
# ? 4. Run 'sudo usbguard generate-policy --device DEVICE_ID | sudo tee -a /etc/usbguard/rules.conf > /dev/null'.
if [ ! -s "$USB_CONFIGURATION" ]; then
    log_info "Configuring USB port protection..."
    sudo usbguard generate-policy | sudo tee "$USB_CONFIGURATION" >/dev/null
    sudo chmod 0600 "$USB_CONFIGURATION"
    sudo chown root:root "$USB_CONFIGURATION"

    # Set the usb_chnages_made flag to 0 (true).
    usb_chnages_made=0
fi

# Restart the usbguard service to apply the changes.
if [ $usb_chnages_made -eq 0 ]; then
    stop_service "usbguard" "Stopping USB port protection..."
    start_service "usbguard" "Starting USB port protection..."
fi

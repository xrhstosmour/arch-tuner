#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
NETWORK_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$NETWORK_SCRIPT_DIRECTORY/../functions.sh"

# Constant variables for reducing trackability configuration.
NETWORK_MANAGER_PACKAGE="NetworkManager"
NETWORK_MANAGER_CONFIGURATION="/etc/NetworkManager/conf.d/00-macrandomize.conf"
NETWORK_MANAGER_WIFI_SCAN_RAND_MAC_ADDRESS="wifi.scan-rand-mac-address=yes"
NETWORK_MANAGER_WIFI_CLONED_MAC_ADDRESS="wifi.cloned-mac-address=random"
NETWORK_MANAGER_ETHERNET_CLONED_MAC_ADDRESS="ethernet.cloned-mac-address=random"

# Check if NetworkManager is installed and active.
if are_packages_installed "$NETWORK_MANAGER_PACKAGE" "$AUR_PACKAGE_MANAGER" && is_service_active "$NETWORK_MANAGER_PACKAGE"; then

    # Check if the settings are already set to reduce trackability.
    if ! grep -q "$NETWORK_MANAGER_WIFI_SCAN_RAND_MAC_ADDRESS" "$NETWORK_MANAGER_CONFIGURATION" ||
        ! grep -q "$NETWORK_MANAGER_WIFI_CLONED_MAC_ADDRESS" "$NETWORK_MANAGER_CONFIGURATION" ||
        ! grep -q "$NETWORK_MANAGER_ETHERNET_CLONED_MAC_ADDRESS" "$NETWORK_MANAGER_CONFIGURATION"; then

        # Reduce trackability.
        log_info "Reducing trackability..."

        # Create or overwrite the configuration file with the desired settings.
        echo -e "[device]\n$NETWORK_MANAGER_WIFI_SCAN_RAND_MAC_ADDRESS\n\n[connection]\n$NETWORK_MANAGER_WIFI_CLONED_MAC_ADDRESS\n$NETWORK_MANAGER_ETHERNET_CLONED_MAC_ADDRESS" | sudo tee "$NETWORK_MANAGER_CONFIGURATION" >/dev/null

        # Restart the NetworkManager service to apply the changes.
        stop_service "$NETWORK_MANAGER_PACKAGE" "Stopping $NETWORK_MANAGER_PACKAGE service..."
        start_service "$NETWORK_MANAGER_PACKAGE" "Starting $NETWORK_MANAGER_PACKAGE service..."
    fi
fi

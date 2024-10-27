#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
NETWORK_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$NETWORK_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$NETWORK_SCRIPT_DIRECTORY/../functions/services.sh"

# Constant variables for reducing trackability configuration.
NETWORK_MANAGER_PACKAGE="NetworkManager"
NETWORK_MANAGER_CONFIGURATION_DIRECTORY="/etc/NetworkManager/conf.d"
NETWORK_MANAGER_CONFIGURATION="/etc/NetworkManager/conf.d/00-macrandomize.conf"
NETWORK_MANAGER_WIFI_SCAN_RAND_MAC_ADDRESS="wifi.scan-rand-mac-address=yes"
NETWORK_MANAGER_WIFI_CLONED_MAC_ADDRESS="wifi.cloned-mac-address=random"
NETWORK_MANAGER_ETHERNET_CLONED_MAC_ADDRESS="ethernet.cloned-mac-address=random"

# Check if NetworkManager is installed and active.
is_network_manager_installed=$(are_packages_installed "$NETWORK_MANAGER_PACKAGE")
is_network_manager_already_active=$(is_service_active "$NETWORK_MANAGER_PACKAGE")

# Proceed only if the machine is not a server and NetworkManager is installed and active.
if [ "$is_network_manager_installed" = "true" ] && [ "$is_network_manager_already_active" = "true" ] && [ "$INSTALLATION_TYPE" != "server" ]; then

    # Create network manager directory if it does not exist.
    if [ ! -d "$NETWORK_MANAGER_CONFIGURATION_DIRECTORY" ]; then
        log_info "Creating $NETWORK_MANAGER_PACKAGE directory..."
        sudo mkdir -p "$NETWORK_MANAGER_CONFIGURATION_DIRECTORY"
    fi

    # TODO: Try using the `change_configuration` function.
    # Check if the settings to reduce trackability are not set in the configuration file or the file does not exist.
    if [ ! -f "$NETWORK_MANAGER_CONFIGURATION" ] ||
        ! grep -q "$NETWORK_MANAGER_WIFI_SCAN_RAND_MAC_ADDRESS" "$NETWORK_MANAGER_CONFIGURATION" ||
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

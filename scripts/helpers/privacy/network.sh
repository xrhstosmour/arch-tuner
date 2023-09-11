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

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

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
if [ "$is_network_manager_installed" = "true" ] && [ "$is_network_manager_already_active" = "true" ]; then

    # Create network manager directory if it does not exist.
    if [ ! -d "$NETWORK_MANAGER_CONFIGURATION_DIRECTORY" ]; then
        log_info "Creating $NETWORK_MANAGER_PACKAGE directory..."
        sudo mkdir -p "$NETWORK_MANAGER_CONFIGURATION_DIRECTORY"
    fi

    # Create the configuration file with the desired settings if it does not exist.
    if [ ! -f "$NETWORK_MANAGER_CONFIGURATION" ]; then
        log_info "Creating $NETWORK_MANAGER_PACKAGE configuration file..."
        log_info "Reducing trackability..."
        echo -e "[device]\n$NETWORK_MANAGER_WIFI_SCAN_RAND_MAC_ADDRESS\n\n[connection]\n$NETWORK_MANAGER_WIFI_CLONED_MAC_ADDRESS\n$NETWORK_MANAGER_ETHERNET_CLONED_MAC_ADDRESS" | sudo tee "$NETWORK_MANAGER_CONFIGURATION" >/dev/null
    fi

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

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions and constant variables.
source "$SCRIPT_DIRECTORY/../functions.sh"
source "$SCRIPT_DIRECTORY/../../core/constants.sh"

# Constant variables for changing and configuring shell.
REFLECTOR_DIRECTORY="/etc/xdg/reflector/"
REFLECTOR_CONFIGURATION="/etc/xdg/reflector/reflector.conf"
REFLECTOR_CONFIGURATION_TO_PASS="../../configurations/mirrors/reflector.conf"

# Installing mirror list manager.
install_packages "reflector" "$AUR_PACKAGE_MANAGER" "Installing mirror list manager..."

# Copy the configuration file only if it is not the same as the current one.
if [ ! -f "$REFLECTOR_CONFIGURATION" ] || ! diff "$REFLECTOR_CONFIGURATION_TO_PASS" "$REFLECTOR_CONFIGURATION" &>/dev/null; then
    echo -e "\n${BOLD_CYAN}Configuring mirror list...${NO_COLOR}"
    sudo mkdir -p "$REFLECTOR_DIRECTORY" && sudo cp -f "$REFLECTOR_CONFIGURATION_TO_PASS" "$REFLECTOR_CONFIGURATION"

    # Read the configuration file into a string, excluding comment lines.
    args=$(grep -v '^#' "$REFLECTOR_CONFIGURATION")

    # Run reflector with the arguments.
    sudo reflector ${args} >/dev/null
fi

# Enable and start mirror list service and timer if they are not already active.
if ! systemctl is-active --quiet reflector; then
    log_info "Enabling and starting mirror list auto refresh service..."
    sudo systemctl enable reflector
    sudo systemctl start reflector
fi
if ! systemctl is-active --quiet reflector.timer; then
    log_info "Enabling and starting mirror list auto refresh timer service..."
    sudo systemctl enable reflector.timer
    sudo systemctl start reflector.timer
fi

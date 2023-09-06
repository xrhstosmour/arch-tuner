#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INFROMATION_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$INFROMATION_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$INFROMATION_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variables for installing and configuring system information tool.
NEOFETCH_DIRECTORY="$HOME/.config/neofetch"
NEOFETCH_CONFIGURATION="$HOME/.config/neofetch/config.conf"
NEOFETCH_CONFIGURATION_TO_PASS="$INFROMATION_SCRIPT_DIRECTORY/../../configurations/information/neofetch.conf"

# Install system information tool package.
install_packages "neofetch" "$AUR_PACKAGE_MANAGER" "Installing system information tool..."

# Configure system information tool.
if ! compare_files "$NEOFETCH_CONFIGURATION" "$NEOFETCH_CONFIGURATION_TO_PASS"; then
    log_info "Configuring system information tool..."
    mkdir -p "$NEOFETCH_DIRECTORY"
    cp -f "$NEOFETCH_CONFIGURATION_TO_PASS" "$NEOFETCH_CONFIGURATION"
fi

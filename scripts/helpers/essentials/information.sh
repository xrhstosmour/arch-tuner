#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SCRIPT_DIRECTORY/../functions.sh"

# Constant variables for installing and configuring system information tool.
NEOFETCH_DIRECTORY="$HOME/.config/neofetch"
NEOFETCH_CONFIGURATION="$HOME/.config/neofetch/config.conf"
NEOFETCH_CONFIGURATION_TO_PASS="$SCRIPT_DIRECTORY/../../configurations/information/neofetch.conf"

# Installing system information tool package.
install_packages "neofetch" "$AUR_PACKAGE_MANAGER" "Installing system information tool..."

# Configuring system information tool.
if [ ! -f "$NEOFETCH_CONFIGURATION" ] || ! diff "$NEOFETCH_CONFIGURATION_TO_PASS" "$NEOFETCH_CONFIGURATION" &>/dev/null; then
    log_info "Configuring system information tool..."
    mkdir -p "$NEOFETCH_DIRECTORY" && cp -f "$NEOFETCH_CONFIGURATION_TO_PASS" "$NEOFETCH_CONFIGURATION"
fi

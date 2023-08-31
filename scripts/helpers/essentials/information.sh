#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Import functions and constant variables.
source ../functions.sh
source ../../core/constants.sh

# Constant variables for installing and configuring system information tool.
NEOFETCH_DIRECTORY="~/.config/neofetch"
NEOFETCH_CONFIGURATION="~/.config/neofetch/config.conf"
NEOFETCH_CONFIGURATION_TO_PASS="../configurations/information/neofetch.conf"

# Installing system information tool package.
install_packages "neofetch" "$AUR_PACKAGE_MANAGER" "Installing system information tool..."

# Configuring system information tool.
if [ ! -f "$NEOFETCH_CONFIGURATION" ] || ! diff "$NEOFETCH_CONFIGURATION_TO_PASS" "$NEOFETCH_CONFIGURATION" &>/dev/null; then
    echo -e "\n${BOLD_CYAN}Configuring system information tool...${NO_COLOR}"
    mkdir -p "$NEOFETCH_DIRECTORY" && cp -f "$NEOFETCH_CONFIGURATION_TO_PASS" "$NEOFETCH_CONFIGURATION"
fi

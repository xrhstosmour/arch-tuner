#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Import functions and constant variables.
source ../functions.sh
source ../../core/constants.sh

# Constant variables for changing and configuring shell.
STARSHIP_DIRECTORY="~/.config"
STARSHIP_CONFIGURATION="~/.config/starship.toml"
STARSHIP_CONFIGURATION_TO_PASS="../../configurations/prompt/configuration.toml"

# Installing prompt.
install_packages "starship" "$AUR_PACKAGE_MANAGER" "Installing prompt..."

# Configuring prompt.
if [ ! -f "$STARSHIP_CONFIGURATION" ] || ! diff "$STARSHIP_CONFIGURATION_TO_PASS" "$STARSHIP_CONFIGURATION" &>/dev/null; then
    echo -e "\n${BOLD_CYAN}Configuring prompt...${NO_COLOR}"
    mkdir -p "$STARSHIP_DIRECTORY" && cp -f "$STARSHIP_CONFIGURATION_TO_PASS" "$STARSHIP_CONFIGURATION"
fi
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
STARSHIP_DIRECTORY="~/.config"
STARSHIP_CONFIGURATION="~/.config/starship.toml"
STARSHIP_CONFIGURATION_TO_PASS="$SCRIPT_DIRECTORY/../../configurations/prompt/configuration.toml"

# Installing prompt.
install_packages "starship" "$AUR_PACKAGE_MANAGER" "Installing prompt..."

# Configuring prompt.
if [ ! -f "$STARSHIP_CONFIGURATION" ] || ! diff "$STARSHIP_CONFIGURATION_TO_PASS" "$STARSHIP_CONFIGURATION" &>/dev/null; then
    log_info "Configuring prompt..."
    mkdir -p "$STARSHIP_DIRECTORY" && cp -f "$STARSHIP_CONFIGURATION_TO_PASS" "$STARSHIP_CONFIGURATION"
fi

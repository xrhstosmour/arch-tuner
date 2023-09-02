#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
PROMPT_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PROMPT_SCRIPT_DIRECTORY/../functions.sh"

# Constant variables for changing and configuring shell.
STARSHIP_DIRECTORY="$HOME/.config"
STARSHIP_CONFIGURATION="$HOME/.config/starship.toml"
STARSHIP_CONFIGURATION_TO_PASS="$PROMPT_SCRIPT_DIRECTORY/../../configurations/prompt/configuration.toml"

# Installing prompt.
install_packages "starship" "$AUR_PACKAGE_MANAGER" "Installing prompt..."

# Configuring prompt.
if ! compare_files "$STARSHIP_CONFIGURATION" "$STARSHIP_CONFIGURATION_TO_PASS"; then
    log_info "Configuring prompt..."
    mkdir -p "$STARSHIP_DIRECTORY"
    cp -f "$STARSHIP_CONFIGURATION_TO_PASS" "$STARSHIP_CONFIGURATION"
fi

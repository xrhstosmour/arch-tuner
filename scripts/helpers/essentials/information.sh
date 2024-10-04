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

# Constant variables for installing and configuring system information tool.
FASTFETCH_DIRECTORY="$HOME/.config/fastfetch"
FASTFETCH_CONFIGURATION="$FASTFETCH_DIRECTORY/config.jsonc"
FASTFETCH_CONFIGURATION_TO_PASS="$INFROMATION_SCRIPT_DIRECTORY/../../configurations/essentials/information/fastfetch.jsonc"

# Install system information tool package.
install_packages "fastfetch" "$AUR_PACKAGE_MANAGER" "Installing system information tool..."

# Configure system information tool.
are_fastfetch_files_the_same=$(compare_files "$FASTFETCH_CONFIGURATION" "$FASTFETCH_CONFIGURATION_TO_PASS")
if [ "$are_fastfetch_files_the_same" = "false" ]; then
    log_info "Configuring system information tool..."
    mkdir -p "$FASTFETCH_DIRECTORY"
    cp -f "$FASTFETCH_CONFIGURATION_TO_PASS" "$FASTFETCH_CONFIGURATION"
fi

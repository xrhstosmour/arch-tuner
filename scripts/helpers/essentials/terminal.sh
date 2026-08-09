#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
TERMINAL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$TERMINAL_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$TERMINAL_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variable for the file path containing the terminal tools to install.
TERMINAL_TOOLS="$TERMINAL_SCRIPT_DIRECTORY/../../packages/essentials/terminal.txt"

# Constant variables for configuring fastfetch.
FASTFETCH_CONFIGURATION_DIRECTORY="$HOME/.config/fastfetch"
FASTFETCH_CONFIGURATION="$HOME/.config/fastfetch/config.jsonc"
FASTFETCH_CONFIGURATION_TO_PASS="$TERMINAL_SCRIPT_DIRECTORY/../../configurations/essentials/terminal/fastfetch/config.jsonc"

# Check if at least one terminal tool is not installed.
are_terminal_packages_installed=$(are_packages_installed "$TERMINAL_TOOLS" "$AUR_PACKAGE_MANAGER")
if [ "$are_terminal_packages_installed" = "false" ]; then
    log_info "Installing terminal tools..."

    # Install terminal tools.
    install_packages "$TERMINAL_TOOLS" "$AUR_PACKAGE_MANAGER"
fi

# Configure fastfetch.
are_fastfetch_configuration_files_the_same=$(compare_files "$FASTFETCH_CONFIGURATION" "$FASTFETCH_CONFIGURATION_TO_PASS")
if [ "$are_fastfetch_configuration_files_the_same" = "false" ]; then
    log_info "Configuring fastfetch..."
    mkdir -p "$FASTFETCH_CONFIGURATION_DIRECTORY"
    cp -f "$FASTFETCH_CONFIGURATION_TO_PASS" "$FASTFETCH_CONFIGURATION"
fi

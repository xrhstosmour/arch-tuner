#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
TERMINAL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$TERMINAL_SCRIPT_DIRECTORY/../functions/packages.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variable for the file path containing the terminal tools to install.
TERMINAL_TOOLS="$TERMINAL_SCRIPT_DIRECTORY/../../packages/essentials/terminal.txt"

# Check if at least one terminal tool is not installed.
are_terminal_packages_installed=$(are_packages_installed "$TERMINAL_TOOLS" "$AUR_PACKAGE_MANAGER")
if [ "$are_terminal_packages_installed" = "false" ]; then
    log_info "Installing terminal tools..."

    # Install terminal tools.
    install_packages "$TERMINAL_TOOLS" "$AUR_PACKAGE_MANAGER"
fi

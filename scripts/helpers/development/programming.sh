#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
PROGRAMMING_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PROGRAMMING_SCRIPT_DIRECTORY/../functions/packages.sh"

# Constant variable for the file path containing the programming languages to install.
PROGRAMMING_LANGUAGES="$PROGRAMMING_SCRIPT_DIRECTORY/../../packages/development/programming.txt"

# Check if at least one programming language package is not installed.
are_programming_packages_installed=$(are_packages_installed "$PROGRAMMING_LANGUAGES" "$AUR_PACKAGE_MANAGER")
if [ "$are_programming_packages_installed" = "false" ]; then
    log_info "Installing programming languages..."

    # Install programming languages packages.
    install_packages "$PROGRAMMING_LANGUAGES" "$AUR_PACKAGE_MANAGER"
fi

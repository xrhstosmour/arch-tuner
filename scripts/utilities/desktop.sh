#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DESKTOP_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DESKTOP_SCRIPT_DIRECTORY/../helpers/functions.sh"

# Constant variable for the file path containing the desktop applications to install.
DESKTOP_PACKAGES="$DESKTOP_SCRIPT_DIRECTORY/../packages/desktop.txt"

# Check if at least one desktop package is not installed.
if ! are_packages_installed "$DESKTOP_PACKAGES" "$AUR_PACKAGE_MANAGER"; then
    log_info "Installing desktop applications..."

    # Installing desktop packages.
    install_packages "$DESKTOP_PACKAGES" "$AUR_PACKAGE_MANAGER"
fi

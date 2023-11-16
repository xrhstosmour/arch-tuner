#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DESKTOP_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DESKTOP_SCRIPT_DIRECTORY/../helpers/functions/packages.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variable for the file path containing the desktop applications to install.
DESKTOP_APPLICATION_PACKAGES="$DESKTOP_SCRIPT_DIRECTORY/../packages/desktop/applications.txt"

# Check if at least one desktop package is not installed.
are_desktop_packages_installed=$(are_packages_installed "$DESKTOP_APPLICATION_PACKAGES" "$AUR_PACKAGE_MANAGER")
if [ "$are_desktop_packages_installed" = "false" ]; then
    log_info "Installing desktop applications..."

    # Install desktop packages.
    install_packages "$DESKTOP_APPLICATION_PACKAGES" "$AUR_PACKAGE_MANAGER"
fi

# Install themes, icons, fonts, cursors.
sh $DESKTOP_SCRIPT_DIRECTORY/../helpers/desktop/theming.sh

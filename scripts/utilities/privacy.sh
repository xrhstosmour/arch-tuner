#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
PRIVACY_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PRIVACY_SCRIPT_DIRECTORY/../helpers/functions/filesystem.sh"
source "$PRIVACY_SCRIPT_DIRECTORY/../helpers/functions/packages.sh"
source "$PRIVACY_SCRIPT_DIRECTORY/../core/flags.sh"

# Install only if the user chooses to install an interface.
if [ $INTERFACE_COMPLETED -eq 0 ]; then

    # Constant variable for the file path containing the privacy applications to install.
    PRIVACY_PACKAGES="$PRIVACY_SCRIPT_DIRECTORY/../packages/privacy/applications.txt"

    # Check if at least one privacy package is not installed.
    are_privacy_packages_installed=$(are_packages_installed "$PRIVACY_PACKAGES" "$AUR_PACKAGE_MANAGER")
    if [ "$are_privacy_packages_installed" = "false" ]; then
        log_info "Installing privacy applications..."

        # Install privacy packages.
        install_packages "$PRIVACY_PACKAGES" "$AUR_PACKAGE_MANAGER"
    fi
fi

# Configure network.
sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/network.sh

# TODO: There are open issues with the kloak package, so this script is not working properly, and it is not recommended to use for now.
# Install and configure keystroke anonymization.
# sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/keyboard.sh

# Configure umask.
sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/umask.sh

# TODO: Implement encrypted swap.

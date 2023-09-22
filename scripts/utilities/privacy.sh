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

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variable for the file path containing the privacy applications to install.
PRIVACY_PACKAGES="$PRIVACY_SCRIPT_DIRECTORY/../packages/privacy.txt"

# Check if at least one privacy package is not installed.
are_privacy_packages_installed=$(are_packages_installed "$PRIVACY_PACKAGES" "$AUR_PACKAGE_MANAGER")
if [ "$are_privacy_packages_installed" = "false" ]; then
    log_info "Installing privacy applications..."

    # Install privacy packages.
    install_packages "$PRIVACY_PACKAGES" "$AUR_PACKAGE_MANAGER"
fi

# Configure network.
sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/network.sh

# TODO: Keystroke anonymization is disabled for now, because it is not working properly.
# Install and configure keystroke anonymization.
# sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/keyboard.sh

# Configure umask.
sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/umask.sh

# TODO: Implement encrypted swap.

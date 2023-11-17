#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
ESSENTIALS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$ESSENTIALS_SCRIPT_DIRECTORY/../helpers/functions/packages.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Install and configure mirror list manager.
sh $ESSENTIALS_SCRIPT_DIRECTORY/../helpers/essentials/mirrors.sh

# Essential packages.
ESSENTIAL_PACKAGES="base-devel git NetworkManager"

# Install essential packages.
are_essential_packages_installed=$(are_packages_installed "$ESSENTIAL_PACKAGES" "$ARCH_PACKAGE_MANAGER")
if [ "$are_essential_packages_installed" = "false" ]; then
    log_info "Installing essential packages..."
    install_packages "$ESSENTIAL_PACKAGES" "$ARCH_PACKAGE_MANAGER"
fi

# Configure Arch package manager.
sh $ESSENTIALS_SCRIPT_DIRECTORY/../helpers/essentials/pacman.sh

# Install and configure AUR helper.
sh $ESSENTIALS_SCRIPT_DIRECTORY/../helpers/essentials/aur.sh

# Install and configure system information tool.
sh $ESSENTIALS_SCRIPT_DIRECTORY/../helpers/essentials/information.sh

# Install terminal tools.
sh $ESSENTIALS_SCRIPT_DIRECTORY/../helpers/essentials/terminal.sh

# Install and configure prompt.
sh $ESSENTIALS_SCRIPT_DIRECTORY/../helpers/essentials/prompt.sh

# Install fonts.
sh $ESSENTIALS_SCRIPT_DIRECTORY/../helpers/essentials/fonts.sh

# Install and configure shell.
sh $ESSENTIALS_SCRIPT_DIRECTORY/../helpers/essentials/shell.sh

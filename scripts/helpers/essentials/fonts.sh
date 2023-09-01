#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Import functions and constant variables.
source ../functions.sh
source ../../core/constants.sh

# Constant variable for the fonts to install.
FONTS="ttf-firacode-nerd"

# Check if at least one font is not installed.
if ! are_packages_installed "$FONTS" "$AUR_PACKAGE_MANAGER"; then
    log_info "Installing fonts..."

    # Installing fonts.
    install_packages "$FONTS" "$AUR_PACKAGE_MANAGER"
fi

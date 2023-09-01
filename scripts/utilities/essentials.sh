#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Import functions.
source ../helpers/functions.sh

# Update system.
log_info "Updating system..."
sudo pacman -S --noconfirm --needed archlinux-keyring &&
    sudo pacman -Syu --noconfirm --needed

# Essential packages.
ESSENTIAL_PACKAGES="base-devel git networkmanager neovim btop"

# Install essential packages.
if ! are_packages_installed "$ESSENTIAL_PACKAGES" "$ARCH_PACKAGE_MANAGER"; then
    log_info "Installing essential packages..."
    install_packages "$ESSENTIAL_PACKAGES" "$ARCH_PACKAGE_MANAGER"
fi

# Give execution permission to all needed scripts.
log_info "Giving execution permission to all scripts..."
chmod +x ../helpers/essentials/aur.sh
chmod +x ../helpers/essentials/information.sh
chmod +x ../helpers/essentials/mirrors.sh
chmod +x ../helpers/essentials/terminal.sh
chmod +x ../helpers/essentials/prompt.sh
chmod +x ../helpers/essentials/fonts.sh
chmod +x ../helpers/essentials/shell.sh

# Install and configure AUR helper.
../helpers/essentials/aur.sh

# Install and configure system information tool.
../helpers/essentials/information.sh

# Install and configure mirror list manager.
../helpers/essentials/mirrors.sh

# Install terminal tools.
../helpers/essentials/terminal.sh

# Install and configure prompt.
../helpers/essentials/prompt.sh

# Install fonts.
../helpers/essentials/fonts.sh

# Install and configure shell.
../helpers/essentials/shell.sh

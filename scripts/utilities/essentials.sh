#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SCRIPT_DIRECTORY/../helpers/functions.sh"

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
chmod +x $SCRIPT_DIRECTORY/../helpers/essentials/aur.sh
chmod +x $SCRIPT_DIRECTORY/../helpers/essentials/information.sh
chmod +x $SCRIPT_DIRECTORY/../helpers/essentials/mirrors.sh
chmod +x $SCRIPT_DIRECTORY/../helpers/essentials/terminal.sh
chmod +x $SCRIPT_DIRECTORY/../helpers/essentials/prompt.sh
chmod +x $SCRIPT_DIRECTORY/../helpers/essentials/fonts.sh
chmod +x $SCRIPT_DIRECTORY/../helpers/essentials/shell.sh

# Install and configure AUR helper.
sh $SCRIPT_DIRECTORY/../helpers/essentials/aur.sh

# Install and configure system information tool.
sh $SCRIPT_DIRECTORY/../helpers/essentials/information.sh

# Install and configure mirror list manager.
sh $SCRIPT_DIRECTORY/../helpers/essentials/mirrors.sh

# Install terminal tools.
sh $SCRIPT_DIRECTORY/../helpers/essentials/terminal.sh

# Install and configure prompt.
sh $SCRIPT_DIRECTORY/../helpers/essentials/prompt.sh

# Install fonts.
sh $SCRIPT_DIRECTORY/../helpers/essentials/fonts.sh

# Install and configure shell.
sh $SCRIPT_DIRECTORY/../helpers/essentials/shell.sh

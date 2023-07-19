#!/bin/bash

# Color for the script's messages.
Cyan='\033[1;36m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Update system.
echo -e "${Cyan}Updating system..."
yes | sudo pacman -Syu

# Install essential packages, if they do not exist.
echo -e "${Cyan}Installing essential packages..."
yes | sudo pacman -S --needed networkmanager base-devel git neovim \
    neofetch btop

# Install paru AUR helper.
echo -e "${Cyan}Installing paru AUR helper..."
if command -v paru &>/dev/null; then
    echo -e "${Cyan}paru AUR helper, already exists in your system!"
else
    git clone https://aur.archlinux.org/paru.git && cd paru &&
        yes | rustup default stable && yes | makepkg -si && cd .. &&
        sudo rm -rf paru
fi

# Configuring paru AUR helper.
echo -e "${Cyan}Configuring paru AUR helper..."
echo -e "${Cyan}Enabling colors in terminal..."
sed -i '/^#.*Color/s/^#//' /etc/pacman.conf
echo -e "${Cyan}Skipping review messages..."
echo -e "SkipReview" >>/etc/paru.conf

# Installing the display manager.
echo -e "${Cyan}Installing display manager..."
yes | paru -S --needed ly-git

# Configuring the display manager.
echo -e "${Cyan}Configuring display manager..."
sudo systemctl enable ly
sed -i '/^#.*blank_password/s/^#//' /etc/ly/config.ini

#!/bin/bash

# Color for the script's messages.
CYAN='\033[1;36m'
NO_COLOR='\033[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Update system.
echo -e "\n${CYAN}Updating system...${NO_COLOR}"
yes | sudo pacman -Syu

# Install essential packages, if they do not exist.
echo -e "\n${CYAN}Installing essential packages...${NO_COLOR}"
yes | sudo pacman -S --needed networkmanager base-devel git neovim \
    neofetch btop

# Install paru AUR helper.
echo -e "\n${CYAN}Installing paru AUR helper...${NO_COLOR}"
if command -v paru &>/dev/null; then
    echo -e "\n${CYAN}paru AUR helper, already exists in your system!${NO_COLOR}"
else

    # Delete old paru directory, if it exists.
    if [ -d "paru" ]; then
        echo -e "\n${CYAN}Deleting old paru directory...${NO_COLOR}"
        sudo rm -rf paru
    fi

    # Proceed with installation.
    git clone https://aur.archlinux.org/paru.git && cd paru &&
        makepkg -si --noconfirm && cd .. && sudo rm -rf paru && cd ~
fi

# Configuring paru AUR helper.
echo -e "\n${CYAN}Configuring paru AUR helper...${NO_COLOR}"

# Changing to stable rust version.
echo -e "\n${CYAN}Changing to stable rust version...${NO_COLOR}"
yes | paru -S --needed rustup && yes | rustup default stable

# Enabling colors in terminal.
echo -e "\n${CYAN}Enabling colors in terminal...${NO_COLOR}"
sudo sed -i '/^#.*Color/s/^#//' /etc/pacman.conf

# Skipping review messages.
echo -e "\n${CYAN}Skipping review messages...${NO_COLOR}"
echo "SkipReview" >>/etc/paru.conf

# Installing the display manager.
echo -e "\n${CYAN}Installing display manager...${NO_COLOR}"
yes | paru -S --needed ly-git

# Configuring the display manager.
echo -e "\n${CYAN}Configuring display manager...${NO_COLOR}"
sudo systemctl enable ly
sudo sed -i '/^#.*blank_password/s/^#//' /etc/ly/config.ini

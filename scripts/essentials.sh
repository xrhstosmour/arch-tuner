#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Update system.
echo "Updating system..."
yes | sudo pacman -Syu

# Install essential packages, if they do not exist.
echo "Installing essential packages..."
yes | sudo pacman -S --needed networkmanager base-devel git neovim \
    neofetch btop

# Install paru AUR helper.
echo "Installing paru AUR helper..."
if command -v paru &>/dev/null; then
    echo "paru AUR helper, already exists in your system!"
else
    git clone https://aur.archlinux.org/paru.git && cd paru &&
        yes | rustup default stable && yes | makepkg -si && cd .. &&
        sudo rm -rf paru
fi

# Configuring paru AUR helper.
echo "Configuring paru AUR helper..."
echo "Enabling colors in terminal..."
sed -i '/^#.*Color/s/^#//' /etc/pacman.conf
echo "Skipping review messages..."
echo "SkipReview" >>/etc/paru.conf

# Installing the display manager.
echo "Installing display manager..."
yes | paru -S --needed ly-git

# Configuring the display manager.
sudo systemctl enable ly
sed -i '/^#.*blank_password/s/^#//' /etc/ly/config.ini

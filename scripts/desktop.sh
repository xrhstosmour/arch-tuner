#!/bin/bash

# Color for the script's messages.
CYAN='\033[1;36m'
NO_COLOR='\033[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Installing desktop applications.
echo -e "\n${CYAN}Installing desktop applications...${NO_COLOR}"
paru -S --noconfirm --needed wezterm dolphin brave-bin gimp veracrypt \
    keepassxc spotify thunderbird vlc davinci-resolve ferdium \
    filen-desktop-appimage viber discord telegram-desktop \
    signal-desktop flameshot libreoffice-fresh pamac

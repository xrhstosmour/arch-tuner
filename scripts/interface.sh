#!/bin/bash

# Color for the script's messages.
CYAN='\033[1;36m'
NO_COLOR='\033[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Installing the display manager.
echo -e "\n${CYAN}Installing display manager...${NO_COLOR}"
yes | paru -S --needed ly-git

# Configuring the display manager.
echo -e "\n${CYAN}Configuring display manager...${NO_COLOR}"
sudo systemctl enable ly
sudo sed -i '/^#.*blank_password/s/^#//' ~/etc/ly/config.ini

# TODO: Install and configure graphics card drivers by auto detect.

#!/bin/bash

# Color for the script's messages.
BOLD_CYAN='\e[1;36m'
NO_COLOR='\e[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Installing firewall and antivirus.
echo -e "\n${BOLD_CYAN}Installing firewall...${NO_COLOR}"
paru -S --noconfirm --needed ufw

# Configuring firewall.
echo -e "\n${BOLD_CYAN}Configuring firewall...${NO_COLOR}"
sudo ufw default allow outgoing
sudo ufw default deny incoming
echo "y" | sudo ufw enable
sudo systemctl start ufw
sudo systemctl enable ufw
sudo ufw reload

# Installing antivirus.
echo -e "\n${BOLD_CYAN}Installing antivirus...${NO_COLOR}"
paru -S --noconfirm --needed clamav

# Configuring antivirus.
echo -e "\n${BOLD_CYAN}Configuring antivirus...${NO_COLOR}"
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam.service
sudo systemctl enable clamav-freshclam.service
sudo systemctl start clamav-daemon.service
sudo systemctl enable clamav-daemon.service

#!/bin/bash

# Color for the script's messages.
BOLD_CYAN='\e[1;36m'
NO_COLOR='\e[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Installing desktop applications.
echo -e "\n${BOLD_CYAN}Installing desktop applications...${NO_COLOR}"
xargs -a ./packages/desktop.txt -r -- paru -S --noconfirm --needed

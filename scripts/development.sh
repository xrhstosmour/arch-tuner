#!/bin/bash

# Color for the script's messages.
BOLD_CYAN='\e[1;36m'
NO_COLOR='\e[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Installing development tools.
echo -e "\n${BOLD_CYAN}Installing development tools...${NO_COLOR}"
xargs -a /packages/development.txt -r -- paru -S --noconfirm --needed

# Configuring development tools.
echo -e "\n${BOLD_CYAN}Configuring development tools...${NO_COLOR}"

# Configuring Docker.
if grep -q "^docker$" /packages/development.txt; then
    echo -e "\n${BOLD_CYAN}Configuring Docker...${NO_COLOR}"
    sudo systemctl enable docker && sudo systemctl start docker
fi

# Installing programming languages.
echo -e "\n${BOLD_CYAN}Installing programming languages...${NO_COLOR}"
xargs -a /packages/programming.txt -r -- paru -S --noconfirm --needed

# Configuring Python poetry.
if grep -q "^python-poetry$" /packages/programming.txt; then
    echo -e "\n${BOLD_CYAN}Configuring Poetry...${NO_COLOR}"
    poetry config virtualenvs.in-project true
fi

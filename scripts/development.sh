#!/bin/bash

# Color for the script's messages.
CYAN='\033[1;36m'
NO_COLOR='\033[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Installing development tools.
echo -e "\n${CYAN}Installing development tools...${NO_COLOR}"
paru -S --noconfirm --needed vscodium-bin remmina-git gitkraken obsidian \
    postman-bin etcher-bin docker docker-compose

# Configuring development tools.
echo -e "Configuring development tools..."
sudo systemctl enable docker && sudo systemctl start docker

# Installing programming languages.
echo -e "\n${CYAN}Installing programming languages...${NO_COLOR}"

# Installing Python.
echo -e "\n${CYAN}Installing Python...${NO_COLOR}"
paru -S --noconfirm --needed python python-pip python-poetry

# Configuring Python.
echo -e "\n${CYAN}Configuring Python...${NO_COLOR}"

# Configuring Poetry.
echo -e "\n${CYAN}Configuring Poetry...${NO_COLOR}"
poetry config virtualenvs.in-project true

# Setting environment variable both for fish and bash shell.
# This is needed to avoid error while adding poetry plugins.
set -x PYTHON_KEYRING_BACKEND 'keyring.backends.null.Keyring'
echo 'export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring' >>~/.bashrc 2>/dev/null
echo 'export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring' >>~/.profile 2>/dev/null

# Installing poetry plugins in a new shell instance to get the environment variable.
"$SHELL" -c 'poetry self add poetry-plugin-up'

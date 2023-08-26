#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Import constant variables and functions.
source ./constants.sh
source ./functions.sh

# Installing development tools.
install_packages_from_file "./packages/development.txt"

# Configuring Docker.
if grep -q "^docker$" ./packages/development.txt; then
    echo -e "\n${BOLD_CYAN}Configuring Docker...${NO_COLOR}"
    sudo systemctl enable docker && sudo systemctl start docker
fi

# Installing programming languages.
install_packages_from_file "./packages/programming.txt"

# Configuring Python poetry.
if grep -q "^python-poetry$" ./packages/programming.txt; then
    echo -e "\n${BOLD_CYAN}Configuring Poetry...${NO_COLOR}"
    poetry config virtualenvs.in-project true
fi

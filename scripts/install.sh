#!/bin/bash

# Color for the script's messages.
CYAN='\033[1;36m'
NO_COLOR='\033[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

echo -e "\n${CYAN}Starting installing procedure...${NO_COLOR}"

# Give execution permission to all scripts.
echo -e "\n${CYAN}Giving execution permission to all scripts...${NO_COLOR}"
chmod +x ./essentials.sh
chmod +x ./development.sh

# Start by executing the essentials script.
./essentials.sh

#  Proceed with the development tools and programming languages.
read -p "\n${CYAN}Do you want to install development tools and programming languages? \nY/N:${NO_COLOR}" answer

# Convert the answer to lowercase to accept 'Y', 'y', 'N', 'n' as valid.
answer=${answer,,}

if [[ "$answer" == "y" ]]; then
    ./development.sh
elif [[ "$answer" != "n" ]]; then
    echo "Invalid input!"
fi

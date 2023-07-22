#!/bin/bash

# Color for the script's messages.
CYAN='\033[1;36m'
BOLD_GREEN='\e[1;${GREEN}m'
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
echo -e "\n${CYAN}Running essentials script...${NO_COLOR}"
./essentials.sh
echo -e "\n${CYAN}Essentials script finished!${NO_COLOR}"

# Proceed with the development script.
echo -e "\n${BOLD_GREEN}Do you want to install development tools and programming languages? Y/N: ${NO_COLOR}"
read -r answer

# Convert the answer to lowercase to accept 'Y', 'y', 'N', 'n' as valid.
answer=${answer,,}

if [[ "$answer" == "y" ]]; then
    echo -e "\n${CYAN}Running development script...${NO_COLOR}"
    ./development.sh
    echo -e "\n${CYAN}Development script finished!${NO_COLOR}"
elif [[ "$answer" != "n" ]]; then
    echo "Invalid input!"
fi

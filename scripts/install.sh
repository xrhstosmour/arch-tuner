#!/bin/bash

# Color for the script's messages.
CYAN='\e[36m'
NO_COLOR='\e[0m'
BOLD_GREEN='\e[1;32m'
BOLD_YELLOW='\e[1;33m'
BOLD_RED='\e[1;31m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Wait for user approval.
echo -e "\n${BOLD_RED}BACKUP EVERYTHING BEFORE PROCEEDING!${NO_COLOR}"
echo -e "\n${BOLD_YELLOW}If not, exit script and re-run after backup!${NO_COLOR}"
echo -e "\n${CYAN}Press ENTER to continue!${NO_COLOR}"

echo -e "\n${CYAN}Starting installing procedure...${NO_COLOR}"

# Give execution permission to all scripts.
echo -e "\n${CYAN}Giving execution permission to all scripts...${NO_COLOR}"
chmod +x ./essentials.sh
chmod +x ./interface.sh
chmod +x ./desktop.sh
chmod +x ./development.sh

# Start by executing the essentials script.
echo -e "\n${CYAN}Running essentials script...${NO_COLOR}"
./essentials.sh
echo -e "\n${CYAN}Essentials script finished!${NO_COLOR}"

# TODO: Convert the repeatable code into a function.
# Default interface answer.
interface_answer=""

# Proceed with the interface script.
while [[ "$interface_answer" != "y" && "$interface_answer" != "n" ]]; do
    echo -e "\n${BOLD_GREEN}Do you want to install display manager and GPU drivers? Y/N: ${NO_COLOR}"
    read -r interface_answer

    # Convert the answer to lowercase to accept 'Y', 'y', 'N', 'n' as valid.
    interface_answer=${interface_answer,,}

    if [[ "$interface_answer" == "y" ]]; then
        echo -e "\n${CYAN}Running interface script...${NO_COLOR}"
        ./interface.sh
        echo -e "\n${CYAN}Interface script finished!${NO_COLOR}"

        # Default dektop answer.
        dektop_answer=""

        # Proceed with the dektop script.
        while [[ "$dektop_answer" != "y" && "$dektop_answer" != "n" ]]; do
            echo -e "\n${BOLD_GREEN}Do you want to install dektop applications? Y/N: ${NO_COLOR}"
            read -r dektop_answer

            # Convert the answer to lowercase to accept 'Y', 'y', 'N', 'n' as valid.
            dektop_answer=${dektop_answer,,}

            if [[ "$dektop_answer" == "y" ]]; then
                echo -e "\n${CYAN}Running dektop script...${NO_COLOR}"
                ./dektop.sh
                echo -e "\n${CYAN}dektop script finished!${NO_COLOR}"
            elif [[ "$dektop_answer" != "n" ]]; then
                echo "Invalid input!"
            fi
        done

        # Default development answer.
        development_answer=""

        # Proceed with the development script.
        while [[ "$development_answer" != "y" && "$development_answer" != "n" ]]; do
            echo -e "\n${BOLD_GREEN}Do you want to install development tools and programming languages? Y/N: ${NO_COLOR}"
            read -r development_answer

            # Convert the answer to lowercase to accept 'Y', 'y', 'N', 'n' as valid.
            development_answer=${development_answer,,}

            if [[ "$development_answer" == "y" ]]; then
                echo -e "\n${CYAN}Running development script...${NO_COLOR}"
                ./development.sh
                echo -e "\n${CYAN}Development script finished!${NO_COLOR}"
            elif [[ "$development_answer" != "n" ]]; then
                echo "Invalid input!"
            fi
        done
    elif [[ "$interface_answer" != "n" ]]; then
        echo "Invalid input!"
    fi
done

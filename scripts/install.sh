#!/bin/bash

# Catch exit signal (CTRL + C) to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INSTALL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Constant variable for the flags script path.
FLAGS_SCRIPT_PATH="$INSTALL_SCRIPT_DIRECTORY/core/flags.sh"

declare -a ORDERED_SCRIPTS=("essentials" "interface" "desktop" "development" "privacy" "security")

# Scripts to run containing their completion flag, initial setup value and optional message, splitted by "|".
declare -A SCRIPTS=(
    ["essentials"]="ESSENTIALS_COMPLETED|1"
    ["interface"]="INTERFACE_COMPLETED|1|Do you want to install display manager and GPU drivers?"
    ["desktop"]="DESKTOP_COMPLETED|1|Do you want to install desktop applications?"
    ["development"]="DEVELOPMENT_COMPLETED|1|Do you want to install development tools and programming languages?"
    ["privacy"]="PRIVACY_COMPLETED|1"
    ["security"]="SECURITY_COMPLETED|1"
)

# TODO: Give execution permission to all the needed scripts.

# Import functions and flags.
source "$INSTALL_SCRIPT_DIRECTORY/helpers/functions/ui.sh"
source "$INSTALL_SCRIPT_DIRECTORY/helpers/functions/system.sh"
source "$INSTALL_SCRIPT_DIRECTORY/helpers/functions/strings.sh"
source "$FLAGS_SCRIPT_PATH"

# Ask user for backup confirmation before proceeding.
if [[ "$INITIAL_SETUP" -eq 0 ]]; then
    ask_for_user_backup_before_proceeding
fi

# Iterate over the scripts and execute them accordingly.
for script in "${ORDERED_SCRIPTS[@]}"; do

    # Split the script info based on the delimiter "|".
    IFS="|" read -ra script_info <<<"${SCRIPTS[$script]}"
    completion_flag="${script_info[0]}"
    message="${script_info[2]}"

    # Check if script has not already been completed.
    if [ "${!completion_flag}" -eq 1 ]; then

        # Flag to track if the user executed a script, 1 (false) by default.
        user_choice=1

        # Check if there's a prompt message for the script.
        if [[ "$message" ]]; then

            # Ask user for approval before executing script and change the flag value accordingly.
            user_answer=$(ask_for_user_approval_before_executing_script "$message" "$INSTALL_SCRIPT_DIRECTORY/utilities/$script.sh")
            [[ "$user_answer" == "y" ]] && user_choice=0 || [[ "$user_answer" == "n" ]] && user_choice=1
        else
            log_info "Executing $script script..."
            sh "$INSTALL_SCRIPT_DIRECTORY/utilities/$script.sh"
            log_info "${script^} script execution finished!"
            user_choice=0
        fi

        # Check if the user executed the script before marking as complete and reboot.
        if [[ "$user_choice" -eq 0 ]]; then

            # Set completion flag to 0 (true) if it's "desktop" or "development".
            [[ "$script" == "desktop" || "$script" == "development" ]] && change_flag_value "$completion_flag" 0 "$FLAGS_SCRIPT_PATH"

            # Reboot system for the rest of the scripts.
            if [[ "$script" == "essentials" || "$script" == "interface" || "$script" == "privacy" ]]; then

                # Before rebooting, if the script is the first one the "essentials" one, change the INITIAL_SETUP flag to 1 (false).
                [[ "$script" == "essentials" ]] && change_flag_value "INITIAL_SETUP" 1 "$FLAGS_SCRIPT_PATH"

                # Proceed with rebooting the system.
                reboot_system "${!completion_flag}" "$completion_flag"
            elif [ "$script" == "security" ]; then
                log_info "Installation procedure finished!"
                log_info "Your system is ready to use!"

                # Do not log the rerun warning.
                reboot_system "${!completion_flag}" "$completion_flag" 1
            fi
        fi
    fi
done

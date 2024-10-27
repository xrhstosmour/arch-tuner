#!/bin/bash

# Catch exit signal (CTRL + C) to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INSTALL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Constant variable for the flags script path.
FLAGS_SCRIPT_PATH="$INSTALL_SCRIPT_DIRECTORY/scripts/core/flags.sh"

declare -a ORDERED_SCRIPTS=("essentials" "interface" "desktop" "development" "privacy" "security")

# Scripts to run containing their completion flag, initial setup value and optional message, splitted by "|".
declare -A SCRIPTS=(
    ["essentials"]="ESSENTIALS_COMPLETED|1"
    ["interface"]="INTERFACE_COMPLETED|1|Would you like to set up the graphical login interface?"
    ["desktop"]="DESKTOP_COMPLETED|1|Would you like to set up the desktop environment?"
    ["development"]="DEVELOPMENT_COMPLETED|1|Would you like to set up the development environment?"
    ["privacy"]="PRIVACY_COMPLETED|1"
    ["security"]="SECURITY_COMPLETED|1"
)

# Import functions and flags.
source "$INSTALL_SCRIPT_DIRECTORY/scripts/helpers/functions/ui.sh"
source "$INSTALL_SCRIPT_DIRECTORY/scripts/helpers/functions/system.sh"
source "$INSTALL_SCRIPT_DIRECTORY/scripts/helpers/functions/strings.sh"
source "$FLAGS_SCRIPT_PATH"
source "$CONSTANTS_SCRIPT_PATH"

# Ask user for backup confirmation before proceeding.
if [[ "$INITIAL_SETUP" -eq 0 ]]; then
    ask_for_user_backup_before_proceeding
fi

# Ask user for system reset if not already completed, before proceeding.
if [[ "$SYSTEM_RESET" -eq 1 ]]; then
    should_reset_system=$(ask_user_before_execution "Would you like to reset your system to a 'clean' state?" "true" "$INSTALL_SCRIPT_DIRECTORY/scripts/helpers/functions/system.sh#reset_system_to_clean_state")
fi

# Ask user for the installation type, before proceeding.
if [[ -z "$INSTALLATION_TYPE" ]]; then
    declare -a INSTALLATION_TYPE_OPTIONS=("minimal" "desktop" "server")
    installation_type=$(choose_option "Select installation type" "${INSTALLATION_TYPE_OPTIONS[@]}")
    change_flag_value "INSTALLATION_TYPE" "$installation_type" "$CONSTANTS_SCRIPT_PATH"
    source "$CONSTANTS_SCRIPT_PATH"
fi

# Update system.
update_system

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
            user_answer=$(ask_user_before_execution "$message" "false" "$INSTALL_SCRIPT_DIRECTORY/scripts/utilities/$script.sh")
            if [[ "$user_answer" == "y" ]]; then
                user_choice=0
            elif [[ "$user_answer" == "n" ]]; then
                user_choice=1
            fi
        else
            log_info "Executing $script script..."
            sh "$INSTALL_SCRIPT_DIRECTORY/scripts/utilities/$script.sh"
            log_success "${script^} script execution finished!"
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
                log_success "Installation procedure finished!"
                log_success "Your system is ready to use!"

                # Do not log the rerun warning.
                reboot_system "${!completion_flag}" "$completion_flag" 1
            fi
        fi
    fi
done

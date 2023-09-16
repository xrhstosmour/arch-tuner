#!/bin/bash

# Catch exit signal (CTRL + C) to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INSTALL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Constant variable for the flags script path.
FLAGS_SCRIPT_PATH="$INSTALL_SCRIPT_DIRECTORY/core/flags.sh"

# Scripts to run and their completion flags
declare -A SCRIPTS=(
    ["essentials"]="ESSENTIALS_COMPLETED"
    ["interface"]="INTERFACE_COMPLETED"
    ["desktop"]="DESKTOP_COMPLETED"
    ["development"]="DEVELOPMENT_COMPLETED"
    ["privacy"]="PRIVACY_COMPLETED"
    ["security"]="SECURITY_COMPLETED"
)

# Prompt messages for the scripts which the user can choose to skip.
declare -A SCRIPT_MESSAGES=(
    ["interface"]="Do you want to install display manager and GPU drivers?"
    ["desktop"]="Do you want to install desktop applications?"
    ["development"]="Do you want to install development tools and programming languages?"
)

# Import functions and flags.
source "$INSTALL_SCRIPT_DIRECTORY/helpers/functions/ui.sh"
source "$INSTALL_SCRIPT_DIRECTORY/helpers/functions/system.sh"
source "$INSTALL_SCRIPT_DIRECTORY/helpers/functions/strings.sh"
source "$FLAGS_SCRIPT_PATH"

# Ask user for backup confirmation before proceeding.
ask_for_user_backup_before_proceeding

# TODO: Ask user if wants to run the script as initial setup or rerun.
# TODO: Give execution permission to all the needed scripts.

# Iterate over the scripts and execute them accordingly.
for script in "${!SCRIPTS[@]}"; do

    # Get the completion flag for the script.
    local completion_flag=${SCRIPTS[$script]}

    # Check if script has not already been completed.
    if [ "${!completion_flag}" -eq 1 ]; then

        # Check if there's a prompt message for the script.
        if [[ "${SCRIPT_MESSAGES[$script]}" ]]; then
            ask_for_user_approval_before_executing_script "${SCRIPT_MESSAGES[$script]}" "$INSTALL_SCRIPT_DIRECTORY/utilities/$script.sh"
        else
            log_info "Executing $script script..."
            sh "$INSTALL_SCRIPT_DIRECTORY/utilities/$script.sh"
            log_info "$script script execution finished!"
        fi

        # Set completion flag to 0 (true) if it's "desktop" or "development".
        [[ "$script" == "desktop" || "$script" == "development" ]] && change_flag_value "$completion_flag" 0 "$FLAGS_SCRIPT_PATH"

        # Reboot system for the rest of the scripts.
        if [[ "$script" == "essentials" || "$script" == "interface" || "$script" == "privacy" ]]; then
            reboot_system "${!completion_flag}" "$completion_flag"
        elif [ "$script" == "security" ]; then
            log_info "Installation procedure finished!"
            log_info "Your system is ready to use!"

            # Do not log the rerun warning.
            reboot_system "${!completion_flag}" "$completion_flag" 1
        fi
    fi
done

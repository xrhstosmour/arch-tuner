#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INSTALL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$INSTALL_SCRIPT_DIRECTORY/helpers/functions/ui.sh"
source "$INSTALL_SCRIPT_DIRECTORY/helpers/functions/system.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Wait for user approval.
log_error "BACKUP EVERYTHING BEFORE PROCEEDING!"
log_warning "If not, exit script and re-run after backup!"
log_info "Press ENTER to continue within next 10 seconds!"

# Read user input with a 10 second timeout.
if ! read -t 10; then
    log_info "Terminating script..."
    exit 1
fi
log_info "Starting installing procedure..."

# TODO: Ask user if wants to run the script as initial setup or rerun.

# Store the original globstar setting
shopt -q globstar
original_globstar=$?

# Enable globstar
shopt -s globstar

# Give execution permissions to all needed scripts.
for script in **/*.sh; do

    # Check if the script isn't executable
    if [[ ! -x "$script" ]]; then
        log_info "Setting execution permissions for script '$script'..."
        chmod +x "$script"
    fi
done

# Restore the original globstar setting
if (($original_globstar == 0)); then
    shopt -u globstar
fi

# Start by executing the essentials script.
if [ "$ESSENTIALS_COMPLETED" -eq 1 ]; then
    log_info "Executing essentials script..."
    sh $INSTALL_SCRIPT_DIRECTORY/utilities/essentials.sh
    log_info "Essentials script execution finished!"

    # Reboot system if needed.
    reboot_system "$ESSENTIALS_COMPLETED" "ESSENTIALS_COMPLETED"
fi

# Use the function to ask user and run scripts.
declare -A scripts=(["interface"]="Do you want to install display manager and GPU drivers?" ["desktop"]="Do you want to install desktop applications?" ["development"]="Do you want to install development tools and programming languages?")
for script in "${!scripts[@]}"; do
    if ([ "$script" == "interface" ] && [ "$INTERFACE_COMPLETED" -eq 1 ]) || [ "$script" != "interface" ]; then
        ask_for_user_approval "${scripts[$script]}" "$INSTALL_SCRIPT_DIRECTORY/utilities/$script.sh"
    fi

    # Reboot system if needed.
    if [ "$script" == "interface" ]; then
        reboot_system "$INTERFACE_COMPLETED" "INTERFACE_COMPLETED"
    fi
done

# Run the privacy script.
if [ "$PRIVACY_COMPLETED" -eq 1 ]; then
    log_info "Executing privacy script..."
    sh $INSTALL_SCRIPT_DIRECTORY/utilities/privacy.sh
    log_info "Privacy script execution finished!"

    # Reboot system if needed.
    reboot_system "$PRIVACY_COMPLETED" "PRIVACY_COMPLETED"
fi

# Run the security script at the end.
if [ "$SECURITY_COMPLETED" -eq 1 ]; then
    log_info "Executing security script..."
    sh $INSTALL_SCRIPT_DIRECTORY/utilities/security.sh
    log_info "Security script execution finished!"

    log_info "Installation procedure finished!"
    log_info "Your system is ready to use!"

    # Reboot system if needed and do not log the rerun warning.
    reboot_system "$SECURITY_COMPLETED" "SECURITY_COMPLETED" 1
fi

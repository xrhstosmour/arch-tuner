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

# Start by executing the essentials script.
log_info "Executing essentials script..."
sh $INSTALL_SCRIPT_DIRECTORY/utilities/essentials.sh
log_info "Essentials script execution finished!"

# Reboot system if needed.
reboot_system "$REBOOTED_AFTER_ESSENTIALS" "REBOOTED_AFTER_ESSENTIALS"

# Use the function to ask user and run scripts.
declare -A scripts=(["interface"]="Do you want to install display manager and GPU drivers?" ["desktop"]="Do you want to install desktop applications?" ["development"]="Do you want to install development tools and programming languages?")
for script in "${!scripts[@]}"; do
    ask_for_user_approval "${scripts[$script]}" "$INSTALL_SCRIPT_DIRECTORY/utilities/$script.sh"

    # Reboot system if needed.
    if [ "$script" == "interface" ]; then
        reboot_system "$REBOOTED_AFTER_INTERFACE" "REBOOTED_AFTER_INTERFACE"
    fi
done

# Run the privacy script.
log_info "Executing privacy script..."
sh $INSTALL_SCRIPT_DIRECTORY/utilities/privacy.sh
log_info "Privacy script execution finished!"

# Reboot system if needed.
reboot_system "$REBOOTED_AFTER_PRIVACY" "REBOOTED_AFTER_PRIVACY"

# Run the security script at the end.
log_info "Executing security script..."
sh $INSTALL_SCRIPT_DIRECTORY/utilities/security.sh
log_info "Security script execution finished!"

log_info "Installation procedure finished!"
log_info "Your system is ready to use!"

# Reboot system if needed and do not log the rerun warning.
reboot_system "$REBOOTED_AFTER_SECURITY" "REBOOTED_AFTER_SECURITY" 1

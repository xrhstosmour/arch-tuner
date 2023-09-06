#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INSTALL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$INSTALL_SCRIPT_DIRECTORY/helpers/functions/logs.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

# Wait for user approval.
log_error "BACKUP EVERYTHING BEFORE PROCEEDING!"
log_warning "If not, exit script and re-run after backup!"
log_info "Press ENTER to continue within next 10 seconds!"

# Read user input with a 10 second timeout.
if read -t 10; then
    log_info "Starting installing procedure..."
else
    log_info "Terminating script..."
    exit 1
fi

# Start by executing the essentials script.
log_info "Executing essentials script..."
sh $INSTALL_SCRIPT_DIRECTORY/utilities/essentials.sh
log_info "Essentials script execution finished!"

# TODO: Convert the repeatable code into a function.
# Default interface answer.
interface_answer=""

# Proceed with the interface script.
while [[ "$interface_answer" != "y" && "$interface_answer" != "n" ]]; do
    log_info "Do you want to install display manager and GPU drivers? Y/N: "
    read -r interface_answer

    # Convert the answer to lowercase to accept 'Y', 'y', 'N', 'n' as valid.
    interface_answer=${interface_answer,,}

    if [[ "$interface_answer" == "y" ]]; then
        log_info "Executing interface script..."
        sh $INSTALL_SCRIPT_DIRECTORY/utilities/interface.sh
        log_info "Interface script execution finished!"
    elif [[ "$interface_answer" != "n" ]]; then
        log_error "Invalid input!"
    fi
done

# Default desktop answer.
desktop_answer=""

# Proceed with the desktop script.
while [[ "$desktop_answer" != "y" && "$desktop_answer" != "n" ]]; do
    log_info "Do you want to install desktop applications? Y/N: "
    read -r desktop_answer

    # Convert the answer to lowercase to accept 'Y', 'y', 'N', 'n' as valid.
    desktop_answer=${desktop_answer,,}

    if [[ "$desktop_answer" == "y" ]]; then
        log_info "Executing desktop script..."
        sh $INSTALL_SCRIPT_DIRECTORY/utilities/desktop.sh
        log_info "Desktop script execution finished!"
    elif [[ "$desktop_answer" != "n" ]]; then
        log_error "Invalid input!"
    fi
done

# Default development answer.
development_answer=""

# Proceed with the development script.
while [[ "$development_answer" != "y" && "$development_answer" != "n" ]]; do
    log_info "Do you want to install development tools and programming languages? Y/N: "
    read -r development_answer

    # Convert the answer to lowercase to accept 'Y', 'y', 'N', 'n' as valid.
    development_answer=${development_answer,,}

    if [[ "$development_answer" == "y" ]]; then
        log_info "Executing development script..."
        sh $INSTALL_SCRIPT_DIRECTORY/utilities/development.sh
        log_info "Development script execution finished!"
    elif [[ "$development_answer" != "n" ]]; then
        log_error "Invalid input!"
    fi
done

# Run the privacy script.
log_info "Executing privacy script..."
sh $INSTALL_SCRIPT_DIRECTORY/utilities/privacy.sh
log_info "Privacy script execution finished!"

# Run the security script at the end.
log_info "Executing security script..."
sh $INSTALL_SCRIPT_DIRECTORY/utilities/security.sh
log_info "Security script execution finished!"

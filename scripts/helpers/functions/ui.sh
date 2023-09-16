#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
UI_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import log functions.
source "$UI_SCRIPT_DIRECTORY/logs.sh"

# Function to ask for user approval before proceeding.
# ask_for_user_backup_before_proceeding
ask_for_user_backup_before_proceeding() {
    log_error "BACKUP EVERYTHING BEFORE PROCEEDING!"
    log_warning -n "If not, exit script and re-run after backup!"
    log_info -n "Press ENTER to continue within next 10 seconds!"

    # Read user input with a 10 second timeout.
    if ! read -t 10; then
        log_info "Terminating script..."
        exit 1
    fi
    log_info "Starting installing procedure..."
}

# Function to ask for user approval and proceed with script execution.
# ask_for_user_approval_before_executing_script "prompt_message" "script_path"
ask_for_user_approval_before_executing_script() {
    local prompt="$1"
    local script_path="$2"
    local script_name=$(basename "$script_path" .sh)

    # Capitalize the first letter.
    local capitalized_script_name="${script_name^}"

    local answer=""
    while [[ "$answer" != "y" && "$answer" != "n" ]]; do
        log_info "$prompt Y/N: "
        read -r answer

        # Convert to lowercase.
        answer=${answer,,}

        if [[ "$answer" == "y" ]]; then
            log_info "Executing $script_name script..."
            sh "$script_path"
            log_info "$capitalized_script_name script execution finished!"
        elif [[ "$answer" != "n" ]]; then
            log_error "Invalid input!"
        fi
    done
}

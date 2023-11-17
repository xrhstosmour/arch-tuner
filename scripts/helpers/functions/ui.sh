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

    # TODO: Ask for desktop only if interface is completed.

    # Capitalize the first letter.
    local capitalized_script_name="${script_name^}"

    # Proceed with the user choice.
    local choice=""
    while :; do
        log_info "$prompt [Y]/N: "
        read -r choice

        # Set default value if no input.
        if [ -z "$choice" ]; then
            choice="Y"
        fi

        # Convert to lowercase.
        choice=${choice,,}

        case "$choice" in
        y)
            log_info "Executing $script_name script..."
            sh "$script_path"
            log_info "$capitalized_script_name script execution finished!"
            echo "$choice"
            break
            ;;
        n)
            echo "$choice"
            break
            ;;
        *)
            log_error "Invalid choice!"
            ;;
        esac
    done
}

# Function to ask user to choose a display manager with default option.
# choose_display_manager
choose_display_manager() {
    local choice=""
    while :; do
        log_info "Choose a display manager [1]/2:"
        log_info -n "1. ly"
        log_info -n "2. sddm"
        read -r choice

        # Set default value if no input.
        if [ -z "$choice" ]; then
            choice="1"
        fi

        # Return the user choice.
        case "$choice" in
        1)
            echo "ly"
            break
            ;;
        2)
            echo "sddm"
            break
            ;;
        *)
            echo "Invalid choice!"
            ;;
        esac
    done
}

# Function to ask user to choose an AUR helper with default option.
# choose_aur_helper
choose_aur_helper() {
    local choice=""
    while :; do
        log_info "Choose an AUR helper [1]/2:"
        log_info -n "1. paru"
        log_info -n "2. yay"
        read -r choice

        # Set default value if no input.
        if [ -z "$choice" ]; then
            choice="1"
        fi

        # Return the user choice.
        case "$choice" in
        1)
            echo "paru"
            break
            ;;
        2)
            echo "yay"
            break
            ;;
        *)
            echo "Invalid choice!"
            ;;
        esac
    done
}

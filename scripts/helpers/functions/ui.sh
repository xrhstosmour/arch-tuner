#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
UI_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import log functions.
source "$UI_SCRIPT_DIRECTORY/logs.sh"

# Function to ask for user approval before proceeding.
# Usage:
#   ask_for_user_backup_before_proceeding
ask_for_user_backup_before_proceeding() {
    log_error "BACKUP EVERYTHING BEFORE PROCEEDING!"
    log_warning -n "If not, exit script and re-run after backup!"
    log_info -n "Press ENTER to continue within next 10 seconds!"

    # Read user input with a 10 second timeout.
    if ! read -t 10; then
        log_info "Terminating script..."
        exit 1
    fi
    log_info "Starting tuning procedure..."
}

# Function to ask for user approval and proceed with script or fucntion execution if provided.
# Usage:
#   For executing a script, provide the full script's path.
#   For executing a function, provide the function's script path and the function name like "../function/path#script_or_function_or_command_name".
#   For executing a plain command, provide the command directly.
#   ask_user_before_execution "prompt_message" "disable_logs" "script_or_function_or_command" "arguments"
ask_user_before_execution() {
    local prompt="$1"
    local disable_logs="$2"
    local script_or_function_or_command="$3"
    shift 3
    local arguments=("$@")

    # Initialize script_or_function_or_command_path and script_or_function_or_command_name.
    local script_or_function_or_command_path=""
    local script_or_function_or_command_name=""
    local capitalized_script_or_function_or_command_name=""

    # Get needed details if a script or function is provided.
    if [ -n "$script_or_function_or_command" ]; then

        # Check if the input contains a '#', which means it's a function.
        if [[ "$script_or_function_or_command" == *"#"* ]]; then

            # Extract script path and function name.
            script_or_function_or_command_path="${script_or_function_or_command%%#*}"
            script_or_function_or_command_name="${script_or_function_or_command##*#}"
        elif [[ -f "$script_or_function_or_command" ]]; then

            # It's a script, so set the script path and name.
            script_or_function_or_command_path="$script_or_function_or_command"
            script_or_function_or_command_name=$(basename "$script_or_function_or_command" .sh)
        else
            # It's a plain command.
            script_or_function_or_command_name="$script_or_function_or_command"
        fi

        # Capitalize the first letter of the script or function name only.
        if [[ "$script_or_function_or_command_name" == *"_"* ]] || [[ -f "$script_or_function_or_command" ]]; then
            capitalized_script_or_function_or_command_name="${script_or_function_or_command_name^}"
        else
            capitalized_script_or_function_or_command_name="$script_or_function_or_command_name"
        fi
    fi

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
            if [ "$disable_logs" = "false" ]; then
                log_info "Executing $script_or_function_or_command_name .."
            fi

            # Execute the script or function or command based on the provided input.
            if [ -n "$script_or_function_or_command" ]; then
                if [[ "$script_or_function_or_command" == *"#"* ]]; then

                    # Before executing the function, we must source the script where it is defined.
                    source "$script_or_function_or_command_path"
                    "$script_or_function_or_command_name" "${arguments[@]}"
                elif [[ -f "$script_or_function_or_command" ]]; then

                    # It's a script, so execute it.
                    sh "$script_or_function_or_command"
                else
                    # It's a plain command, so execute it.
                    eval "$script_or_function_or_command ${arguments[*]}"
                fi
            else
                log_error "Invalid script or function or command: $script_or_function_or_command"
                return 1
            fi

            if [ "$disable_logs" = "false" ]; then
                log_success "$capitalized_script_or_function_or_command_name execution finished!"
            fi

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

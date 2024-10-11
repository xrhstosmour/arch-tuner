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
    log_info -n "Starting tuning procedure..."
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
        log_info "$prompt [y/N]: "
        read -r choice

        # Set default value if no input.
        if [ -z "$choice" ]; then
            choice="N"
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

# Function to ask user to choose an option with the fist one as default.
# Usage:
#   choose_option "prompt_message" "options_array"
choose_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local default_option="${options[0]}"
    local choice=""

    # Construct the options prompt string.
    local options_prompt="[1]"
    for i in $(seq 2 ${#options[@]}); do
        options_prompt+="/$i"
    done
    options_prompt+=":"

    # Iterate until a valid choice is made.
    while :; do
        log_info "$prompt $options_prompt"
        for i in "${!options[@]}"; do
            log_info -n "$((i + 1)). ${options[i]}"
        done
        read -r choice

        # Set default value if no input.
        if [ -z "$choice" ]; then
            choice="1"
        fi

        # Validate and return the user choice.
        if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#options[@]}" ]; then
            echo "${options[$((choice - 1))]}"
            break
        else
            log_error "Invalid choice!"
        fi
    done
}

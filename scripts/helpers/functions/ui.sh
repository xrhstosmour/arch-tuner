#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
UI_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import log functions.
source "$UI_SCRIPT_DIRECTORY/logs.sh"

# Function to ask for user approval and proceed with script execution.
# ask_for_user_approval "prompt_message" "script_path"
ask_for_user_approval() {
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
            log_info "Executing $script_name scipt..."
            sh "$script_path"
            log_info "$capitalized_script_name execution finished!"
        elif [[ "$answer" != "n" ]]; then
            log_error "Invalid input!"
        fi
    done
}

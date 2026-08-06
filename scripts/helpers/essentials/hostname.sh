#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
HOSTNAME_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$HOSTNAME_SCRIPT_DIRECTORY/../functions/ui.sh"
source "$HOSTNAME_SCRIPT_DIRECTORY/../functions/state.sh"

# Skip prompting if a hostname has already been chosen on a previous run.
source_state
if [ "$HOSTNAME_SET" = "1" ]; then
    log_info "Hostname already configured."
else
    current_hostname=$(hostnamectl --static)

    # Prompt until a valid RFC 1123 hostname label is given: lowercase
    # letters, digits and hyphens, 1-63 characters, no leading/trailing hyphen.
    while :; do
        hostname=$(prompt_user_input "Enter hostname for this machine" "$current_hostname")

        if [[ "$hostname" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; then
            break
        fi

        log_error "Invalid hostname: '$hostname'. Use up to 63 lowercase letters, digits, or hyphens, not starting or ending with a hyphen."
    done

    sudo hostnamectl set-hostname "$hostname"
    log_success "Hostname set to $hostname."

    change_flag_value "HOSTNAME_SET" 1
fi

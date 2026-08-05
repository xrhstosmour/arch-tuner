#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
USER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$USER_SCRIPT_DIRECTORY/../functions/logs.sh"
source "$USER_SCRIPT_DIRECTORY/../functions/ui.sh"

# Prompt for the administrative username, requiring a valid Linux username as defense-in-depth
# before it reaches `useradd`/`passwd`.
while :; do
    username=$(prompt_user_input "Enter username for administrative user" "admin")

    if [[ "$username" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        break
    fi

    log_error "Invalid username: '$username'. Use up to 32 lowercase letters, digits, underscores, or hyphens, starting with a letter or underscore."
done

# Check if the user already exists.
if id "$username" &>/dev/null; then
    log_info "User $username already exists."
else
    # Create the user with home directory and add to the wheel group.
    sudo useradd -m -G wheel "$username"
    log_success "User $username created and added to wheel."
fi

# Set the password for the user.
sudo passwd "$username"
log_info "Password set for $username. Ensure root login is disabled via SSH hardening."

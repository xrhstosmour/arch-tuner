#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
SYSTEM_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import log functions.
source "$SYSTEM_SCRIPT_DIRECTORY/logs.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

# Function to update system.
# update_system
update_system() {

    # Update package databases.
    sudo pacman -Sy

    # Check if any package is upgradable.
    upgradable=$(pacman -Qu) || true

    # Check if 'archlinux-keyring' package is upgradable.
    upgradable_keyring=$(echo "$upgradable" | grep archlinux-keyring) || true

    # Update 'archlinux-keyring' package if it needs an update.
    if [[ -n "$upgradable_keyring" ]]; then
        log_info "Updating archlinux-keyring..."
        sudo pacman -S --noconfirm --needed archlinux-keyring
    fi

    # Update system if any package is upgradable.
    if [[ -n "$upgradable" ]]; then
        log_info "Updating system..."
        sudo pacman -Su --noconfirm --needed
    fi
}

# Function to stop a process.
# stop_process "process_name" "message"
stop_process() {
    local process_name="$1"
    local message="${2:-"Stopping $process_name process..."}"

    # Find the process IDs of the process name.
    local process_ids=$(ps aux | grep "$process_name" | grep -v 'grep' | awk '{print $2}')

    # Check if any process IDs were found.
    if [ -n "$process_ids" ]; then
        log_info "$message"

        # Loop through each PID and try to gracefully kill it.
        for process_id in $process_ids; do
            kill "$process_id"
            sleep 1 # Give it a second to terminate
        done

        # Check if any PIDs still exist, then forcefully kill them.
        remaining_process_ids=$(ps aux | grep "$process_name" | grep -v 'grep' | awk '{print $2}')
        if [ -n "$remaining_process_ids" ]; then
            for remaining_process_id in $remaining_process_ids; do
                kill -9 "$remaining_process_id"
            done
        fi
    fi
}

# Function to check if a process is running by its name.
# is_process_running "process_name"
is_process_running() {
    local process_name="$1"

    # Find the process IDs of the process name.
    local process_ids=$(ps aux | grep "$process_name" | grep -v 'grep' | awk '{print $2}')

    # Check if any process IDs were found.
    if [ -n "$process_ids" ]; then
        # Return 0 (true) to indicate that the process is running.
        return 0
    else
        # Return 1 (false) to indicate that the process is not running.
        return 1
    fi
}

# Function to reboot system if needed.
# reboot_system "value_to_check" "variable_to_change" "0_or_1_to_log_warning"
reboot_system() {
    local value_to_check="$1"
    local variable_to_change="$2"

    # Defaults to 0 (true) to log the warning.
    local log_rerun_warning="${3:-0}"

    # Constant variable for the constant script path.
    local constant_script_path="$SYSTEM_SCRIPT_DIRECTORY/../../core/constant.sh"

    # Check the value is not equal to 0 (true) and reboot.
    if [ "$value_to_check" -ne 0 ]; then
        log_error "System requires a reboot to apply changes!"
        if [ "$log_rerun_warning" -eq 0 ]; then
            log_warning "After the system restarts, please rerun the entire script!"
        fi
        log_info "Initiating system reboot..."

        # Use sed to set variable_to_change to 0 in the constant.sh file
        # Match any value after the equals sign and replace with 0
        sed -i "s/^$variable_to_change=[0-9]*\$/$variable_to_change=0/" "$constant_script_path"

        # Reboot the system.
        sudo reboot
    fi
}

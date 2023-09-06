#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
FILESYSTEM_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import constant variables.
source "$FILESYSTEM_SCRIPT_DIRECTORY/../../core/constants.sh"

# Import log functions.
source "$FILESYSTEM_SCRIPT_DIRECTORY/logs.sh"

# Function to check if a line exists in a file and add it if it does not.
# append_line_to_file "/file/path/with.extension" "Line To Append" "Message to print if the line is appended."
append_line_to_file() {
    local file_path="$1"
    local line_to_append="$2"
    local message="$3"

    if ! grep -qxF "$line_to_append" "$file_path"; then

        # Print message if it exists.
        if [ -n "$message" ]; then
            log_info "$message"
        fi

        # Append line to file.
        echo "$line_to_append" | sudo tee -a "$file_path" >/dev/null

        # Return 0 (true) to indicate that a change was made.
        return 0
    fi

    # Return 1 (false) to indicate that no change was made.
    return 1
}

# Function to add options to a mount point.
# add_mount_options "/path/to/mount/point" "option1,opption2,option3"
add_mount_options() {
    local mount_point="$1"
    local options="$2"

    # Check if the options are already present and if not add them.
    if ! grep -q " $mount_point .*defaults,.*$options" /etc/fstab; then
        if grep -q " $mount_point " /etc/fstab; then
            log_info "Adding options $options to mount point $mount_point..."
            sudo sed -i "s|\($mount_point .*\) defaults |\1 defaults,$options |" /etc/fstab

            # Return 0 (true) to indicate that a change was made.
            return 0
        fi
    fi

    # Return 1 (false) to indicate that no change was made.
    return 1
}

# Function to compare two files.
# compare_files "target_file" "source_file"
compare_files() {
    local target_file=$1
    local source_file=$2

    # If the target file does not exist or is different from the source file, return 1 (false).
    # If the target file exists and is the same as the source file, return 0 (true).
    if [ ! -f "$target_file" ] || ! diff "$source_file" "$target_file" &>/dev/null; then
        return 1
    else
        return 0
    fi
}

# Function to give execution permission to scripts.
give_execution_permission_to_scripts() {

    # Take all the arguments as an array.
    local scripts=("$@")

    # Pop the last element from the array and assign it to message.
    local message="${scripts[-1]:-"Giving execution permission to needed scripts."}"

    # Remove the last element from the array.
    unset 'scripts[${#scripts[@]}-1]'

    # Initialize a variable to track if logging is needed.
    local need_to_log=false

    # First loop to check if any script needs execute permission.
    for script in "${scripts[@]}"; do
        if [[ ! -x "$script" ]]; then

            # Set the flag to true as at least one script needs permission.
            need_to_log=true
            break
        fi
    done

    # Log only if at least one script needed permission change.
    if [ "$need_to_log" = true ]; then
        log_info "$message"
    fi

    # Second loop to actually give execute permission if not already set.
    for script in "${scripts[@]}"; do
        if [[ ! -x "$script" ]]; then
            chmod +x "$script"
        fi
    done
}

#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
FILESYSTEM_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import log functions.
source "$FILESYSTEM_SCRIPT_DIRECTORY/logs.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

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

        # Return true to indicate that a change was made.
        echo "true"
    fi

    # Return false to indicate that no change was made.
    echo "false"
}

# Function to add options to a mount point.
# add_mount_options "/path/to/mount/point" "option1,opption2,option3"
add_mount_options() {
    local mount_point="$1"
    local options="$2"

    # Get the device associated with the mount point.
    local device=$(findmnt -n -o SOURCE --target "$mount_point")

    # If no device found for the given mount point, exit the function
    if [ -z "$device" ]; then
        log_info "No device found for mount point $mount_point!"

        # Return false to indicate that no change was made.
        echo "false"
        return
    fi

    # Get the UUID and filesystem type.
    local uuid=$(sudo blkid -o value -s UUID "$device")
    local fs_type=$(sudo blkid -o value -s TYPE "$device")

    # Check if the options are already present.
    if ! grep -qE "^UUID=$uuid\s+$mount_point\s+$fs_type\s+.*$options" /etc/fstab; then
        # Check if the mount point exists but doesn't have the desired options.
        if grep -qE "^UUID=$uuid\s+$mount_point\s+$fs_type\s+" /etc/fstab; then
            log_info "Adding options $options to mount point $mount_point..."
            sudo sed -i "s|^\(UUID=$uuid\s+$mount_point\s+$fs_type\s+\)\(.*\)|\1\2,$options|" /etc/fstab

            # Return true to indicate that a change was made.
            echo "true"
            return
        else
            # If the mount point doesn't exist, add a new entry.
            log_info "Creating $mount_point mount point with options $options..."
            echo "UUID=$uuid  $mount_point  $fs_type  defaults,$options  0 2" | sudo tee -a /etc/fstab

            # Return true to indicate that a change was made.
            echo "true"
            return
        fi
    fi

    # Return false to indicate that no change was made.
    echo "false"
}

# Function to compare two files.
# compare_files "target_file" "source_file"
compare_files() {
    local target_file=$1
    local source_file=$2

    # If the target file does not exist or is different from the source file, return false.
    # If the target file exists and is the same as the source file, return true.
    if [ ! -f "$target_file" ] || ! diff "$source_file" "$target_file" &>/dev/null; then
        echo "false"
    else
        echo "true"
    fi
}

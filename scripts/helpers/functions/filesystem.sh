#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
FILESYSTEM_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import log functions.
source "$FILESYSTEM_SCRIPT_DIRECTORY/logs.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

# Function to check if a line exists in a file and add it if it does not.
# Usage:
#   append_line_to_file "/file/path/with.extension" "Line To Append" "Message to print if the line is appended."
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

# Function to move existing files to a new mount before changing fstab.
# Usage:
#   move_files_to_temporary_mount "/mount/point" "device"
move_files_to_temporary_mount() {
    local mount_point="$1"
    local device="$2"

    # Before adding a new mount point, check if the directory contains any files.
    if [[ $(sudo find "$mount_point" -mindepth 1 | wc -l) -gt 0 ]]; then
        log_info "Moving $mount_point's files to a temporaty mount..."

        # Mount the new device to a temporary migration location to transfer the files.
        local temporary_directory="/mnt/mgrtn_${mount_point#/}"
        sudo mkdir -p "$temporary_directory"

        # Mount according to device.
        if [[ "$device" == "tmpfs" ]]; then
            sudo mount -t tmpfs tmpfs "$temporary_directory"
        else
            sudo mount "$device" "$temporary_directory"
        fi

        # Copy files from the old mount point to the new mount point.
        sudo cp -a "$mount_point/"* "$temporary_directory/"

        # Sleep for 10 seconds after copying files.
        sleep 10

        # Remove the mount point.
        sudo rmdir --ignore-fail-on-non-empty "$mount_point"

        # Sleep for 10 seconds after deleting mount point files.
        sleep 10

        # Unmount the temporary mount point.
        sudo umount "$temporary_directory"

        # Sleep for 10 seconds after unmounting temporary directory.
        sleep 10

        # Remove the temporaty directory.
        sudo rmdir --ignore-fail-on-non-empty "$temporary_directory"

        # Sleep for 10 seconds after deleting temporary directory's files.
        sleep 10
    fi
}

# Function to apply mount hardening options to a mount point in /etc/fstab.
# Usage:
#   update_mount_options "/mount/point" "option1,option2,option3"
update_mount_options() {
    local mount_point="$1"
    local options="$2"

    # Check if the mount point exists in /etc/fstab.
    if sudo awk '$2 == "'"$mount_point"'" && $1 !~ /^#/' /etc/fstab | grep -q .; then
        # Mount point found in fstab. Get current options.
        local current_options
        current_options=$(sudo awk -v mp="$mount_point" '$2 == mp && $1 !~ /^#/{print $4}' /etc/fstab)

        # Convert the current and new options into arrays for easier processing.
        IFS=',' read -ra current_options_array <<<"$current_options"
        IFS=',' read -ra new_options_array <<<"$options"

        # Create an associative array to hold unique options.
        declare -A unique_options
        for current_option in "${current_options_array[@]}"; do
            unique_options["$current_option"]=1
        done
        for new_option in "${new_options_array[@]}"; do
            unique_options["$new_option"]=1
        done

        # Create the modified options string from the unique options.
        local modified_options
        modified_options=$(echo "${!unique_options[@]}" | tr ' ' ',')

        # Update the fstab entry if necessary.
        if [[ "$modified_options" != "$current_options" ]]; then
            log_info "Appending options $options to mount point $mount_point..."
            sudo awk -v mount="$mount_point" -v opts="$modified_options" '
            {
                # If the line contains the target mount point and is not commented
                if ($2 == mount && $1 !~ /^#/) {
                    # Set the options
                    $4 = opts
                }
                # Print each line (modified or not)
                print
            }
            ' /etc/fstab >/tmp/fstab.tmp && sudo mv /tmp/fstab.tmp /etc/fstab

            # Return true to indicate that a change was made.
            echo "true"
        else
            # No change needed.
            echo "false"
        fi
    else

        # Find the device the filesystem and the uuid for possible new mount points.
        local device=$(findmnt -nr -o SOURCE --target "$mount_point")
        device="${device%%[[]*}"
        local filesystem=$(findmnt -nr -o FSTYPE --target "$mount_point")
        local uuid=""

        # Check if filesystem is valid.
        if [[ -n "$filesystem" ]]; then

            # Get UUID when filesystem is not tmpfs.
            if [[ "$filesystem" != "tmpfs" ]]; then
                uuid=$(sudo blkid -s UUID -o value "$device")

                # Proceed with adding the new mount point.
                if [[ -n "$uuid" ]]; then
                    move_files_to_temporary_mount "$mount_point" "$device"
                    log_info "Adding new mount point $mount_point with options $options..."
                    echo "UUID=$uuid $mount_point $filesystem $options 0 0" | sudo tee -a /etc/fstab

                    # Return true to indicate that a change was made.
                    echo "true"
                else
                    log_error "Failed to retrieve UUID for mount point $mount_point and device $device!"

                    # Return false to indicate that no change was made.
                    echo "false"
                fi
            else
                move_files_to_temporary_mount "$mount_point" "$device"
                log_info "Adding new tmpfs mount point $mount_point with options $options..."
                echo "$device $mount_point $filesystem $options 0 0" | sudo tee -a /etc/fstab

                # Return true to indicate that a change was made.
                echo "true"
            fi
        else
            log_error "Failed to retrieve filesystem type for mount point $mount_point!"

            # Return false to indicate that no change was made.
            echo "false"
        fi
    fi
}

# Function to compare two files.
# Usage:
#   compare_files "target_file" "source_file"
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

# Function to check if a directory is in the excluded list
# Usage:
#   directory_exists_in_list "directory" "directory_list"
directory_exists_in_list() {
    local directory="$1"

    # Declare a local array by dereferencing the passed array name.
    local -n directory_list="$2"

    # Iterate and check if the directory exists in the list.
    for excluded_dir in "${directory_list[@]}"; do
        if [[ "$directory" == "$excluded_dir" ]]; then
            echo "true"
            return
        fi
    done
    echo "false"
}

# Function to check if a file contains another file.
# Usage:
#   file_contains_file "file_to_check" "file_to_check_if_is_contained"
is_file_contained_in_another() {
    local file_to_check="$1"
    local file_to_check_if_is_contained="$2"

    # Check if both files exist and are not empty.
    if [ -s "$file_to_check" ] && [ -s "$file_to_check_if_is_contained" ]; then

        # Check if the first file contains the second file.
        if comm -13 <(sort -u "$file_to_check") <(sort -u "$file_to_check_if_is_contained") | grep -q .; then
            echo "false"
        else
            echo "true"
        fi
    else
        echo "false"
    fi
}

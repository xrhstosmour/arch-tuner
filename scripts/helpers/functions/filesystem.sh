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

# Function to apply mount hardening options to a mount point in /etc/fstab.
# update_mount_options "/mount/point" "option1,option2,option3"
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
        # Mount point not found in fstab.
        echo "false"
    fi
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

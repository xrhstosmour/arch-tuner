#!/bin/bash

# Import constant variables.
source ./constants.sh

# Function to check if a line exists in a file and add it if it does not.
# append_line_to_file "/file/path/with.extension" "Line To Append" "Message to print if the line is appended."
append_line_to_file() {
    file_path="$1"
    line_to_append="$2"
    message="$3"

    if ! grep -qxF "$line_to_append" "$file_path"; then

        # Print message if it exists.
        if [ -n "$message" ]; then
            echo -e "\n${BOLD_CYAN}""$message""${NO_COLOR}"
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
            echo -e "\n${BOLD_CYAN}Adding options $options to mount point $mount_point...${NO_COLOR}"
            sudo sed -i "s|\($mount_point .*\) defaults |\1 defaults,$options |" /etc/fstab

            # Return 0 (true) to indicate that a change was made.
            return 0
        fi
    fi

    # Return 1 (false) to indicate that no change was made.
    return 1
}

# Function to handle the interrupt signal.
handle_interrupt_signal() {
    echo -e "\n${BOLD_RED}Interrupt signal received, exiting...${NO_COLOR}"
    exit 1
}

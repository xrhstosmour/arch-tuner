#!/bin/bash

# Import constant variables.
source ./constants.sh

# Function to check if a line exists in a file and add it if it does not.
append_line_to_file() {
    file_path="$1"
    line_to_check="$2"
    message="$3"

    if ! grep -qxF "$line_to_check" "$file_path"; then

        # Print message if it exists.
        if [ -n "$message" ]; then
            echo -e "$message"
        fi

        # Append line to file.
        echo "$line_to_check" | sudo tee -a "$file_path" >/dev/null

        # Return true to indicate that a change was made.
        return true
    fi

    # Return false to indicate that no change was made.
    return false
}

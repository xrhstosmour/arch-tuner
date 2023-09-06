#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
STRINGS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Function to trim a string.
# trim_string "string_to_trim"
trim_string() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

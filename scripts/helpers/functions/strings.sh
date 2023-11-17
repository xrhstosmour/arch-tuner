#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
STRINGS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Function to trim a string.
# trim_string "string_to_trim"
trim_string() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Function to change a flag value to the given value.
# change_flag_value "flag" "value" "script_path"
change_flag_value() {
    local flag=$1
    local value=$2
    local script_path=$3

    # Check if the value is an integer.
    if [[ $value =~ ^[0-9]+$ ]]; then

        # If it's an integer, don't add quotes.
        sed -i "s/^$flag=.*\$/$flag=$value/" "$script_path"
    else

        # If it's not an integer, add quotes.
        sed -i "s/^$flag=.*\$/$flag=\"$value\"/" "$script_path"
    fi
}

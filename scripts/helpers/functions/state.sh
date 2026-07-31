#!/bin/bash

# shellcheck disable=SC2034

# Constant variable for the state directory and file.
STATE_DIRECTORY="${ARCH_TUNER_STATE_DIRECTORY:-/var/lib/arch-tuner}"
STATE_FILE="$STATE_DIRECTORY/state.sh"

# Function to change a flag value to the given value in the state file.
# change_flag_value "flag" "value"
change_flag_value() {
    local flag="$1"
    local value="$2"

    # Ensure the state directory exists.
    mkdir -p "$STATE_DIRECTORY"

    # If the state file doesn't exist, create it.
    if [[ ! -f "$STATE_FILE" ]]; then
        : > "$STATE_FILE"  # Empty file
    fi

    # Use a temporary file for atomic update.
    local temp_file
    temp_file=$(mktemp "$STATE_FILE.tmp.XXXXXX")

    # Write the updated flag value.
    if [[ $value =~ ^[0-9]+$ ]]; then
        # If it's an integer, don't add quotes.
        if grep -q "^$flag=" "$STATE_FILE"; then
            # Replace existing flag line
            sed "s/^$flag=.*/$flag=$value/" "$STATE_FILE" > "$temp_file"
        else
            # Add new flag line
            cat "$STATE_FILE" > "$temp_file"
            echo "$flag=$value" >> "$temp_file"
        fi
    else
        # If it's not an integer, add quotes.
        if grep -q "^$flag=" "$STATE_FILE"; then
            # Replace existing flag line
            sed "s/^$flag=.*/\"$flag=$value\"/" "$STATE_FILE" > "$temp_file"
        else
            # Add new flag line
            cat "$STATE_FILE" > "$temp_file"
            echo "$flag=\"$value\"" >> "$temp_file"
        fi
    fi

    # Atomically replace the state file.
    mv "$temp_file" "$STATE_FILE"
}

# Function to source the state file if it exists.
# source_state
source_state() {
    if [[ -f "$STATE_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$STATE_FILE"
    fi
}

# Function to remove the state file.
# reset_state
reset_state() {
    if [[ -f "$STATE_FILE" ]]; then
        rm -f "$STATE_FILE"
    fi
}

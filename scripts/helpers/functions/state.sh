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

    # Guard against values that could corrupt the state file.
    if [[ $value == *\"* || $value == *\\* || $value == *$'\n'* ]]; then
        echo "invalid value" >&2
        return 1
    fi

    # Ensure the state directory exists.
    mkdir -p "$STATE_DIRECTORY"

    # Write to a temporary file, then atomically replace the state file.
    local temp_file
    temp_file=$(mktemp "$STATE_DIRECTORY/.state.XXXXXX")

    # Drop any existing line for this flag, then append the new value.
    grep -v -F -- "$flag=" "$STATE_FILE" 2>/dev/null > "$temp_file" || true
    if [[ $value =~ ^[0-9]+$ ]]; then
        printf '%s=%s\n' "$flag" "$value" >> "$temp_file"
    else
        printf '%s="%s"\n' "$flag" "$value" >> "$temp_file"
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

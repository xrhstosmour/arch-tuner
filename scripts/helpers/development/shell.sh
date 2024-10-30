#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SHELL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SHELL_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$SHELL_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variables for configuring shell.
FISH_CONFIGURATION="$HOME/.config/fish/config.fish"
FISH_ABBREVIATIONS="$HOME/.config/fish/conf.d/abbr.fish"
FISH_ABBREVIATIONS_TO_PASS="$SHELL_SCRIPT_DIRECTORY/../../configurations/development/shell/abbreviations.fish"
FISH_FUNCTIONS="$HOME/.config/fish/functions"
FISH_FUNCTIONS_TO_PASS="$SHELL_SCRIPT_DIRECTORY/../../configurations/development/shell/functions"

# Check if `FISH_ABBREVIATIONS_TO_PASS` is contained in `FISH_ABBREVIATIONS` and append if not.
is_abbreviations_file_contained=$(is_file_contained_in_another "$FISH_ABBREVIATIONS" "$FISH_ABBREVIATIONS_TO_PASS")
if [ "$is_abbreviations_file_contained" = "false" ]; then
    log_info "Appending development abbreviations to the shell configuration..."
    [ -n "$(tail -n 1 "$FISH_ABBREVIATIONS")" ] && echo "" | sudo tee -a "$FISH_ABBREVIATIONS" >/dev/null
    cat "$FISH_ABBREVIATIONS_TO_PASS" | sudo tee -a "$FISH_ABBREVIATIONS" >/dev/null
fi

# Configure shell functions.
configure_fish_shell_files "$FISH_CONFIGURATION" "$FISH_FUNCTIONS_TO_PASS" "$FISH_FUNCTIONS" "development functions"

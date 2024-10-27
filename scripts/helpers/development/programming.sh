#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
PROGRAMMING_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# List of available programming languages.
declare -A LANGUAGE_COMMANDS=(
    ["Ruby"]="mise use --global ruby@latest"
    ["Node.js"]="mise use --global node@lts"
    ["Go"]="mise use --global go@latest"
    ["Python"]="mise use --global python@latest"
    ["Java"]="mise use --global java@latest"
    [".NET"]="paru -S --noconfirm --needed dotnet-sdk dotnet-runtime aspnet-runtime"
)
# Import functions and flags.
source "$PROGRAMMING_SCRIPT_DIRECTORY/../functions/ui.sh"

log_info "Installing programming languages..."

# Iterate over the available languages and ask the user to install them
for language in "${!LANGUAGE_COMMANDS[@]}"; do
    message="Do you want to install $language?"
    user_answer=$(ask_user_before_execution "$message" "false" "${LANGUAGE_COMMANDS[$language]}")
done

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
MIRRORS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions and flags.
source "$MIRRORS_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$MIRRORS_SCRIPT_DIRECTORY/../functions/filesystem.sh"
source "$MIRRORS_SCRIPT_DIRECTORY/../functions/services.sh"
source "$MIRRORS_SCRIPT_DIRECTORY/../../core/flags.sh"

# Define the rate-mirrors script file and command.
RATE_MIRRORS_SCRIPT="$MIRRORS_SCRIPT_DIRECTORY/../../configurations/essentials/mirrors/rate-mirrors.sh"
RATE_MIRRORS_COMMAND=$(cat "$RATE_MIRRORS_SCRIPT")

# Install mirror list manager and execute the command.
install_packages "rate-mirrors-bin" "$AUR_PACKAGE_MANAGER" "Installing mirror list manager..."
log_info "Configuring mirror list..."
/bin/bash -c "$RATE_MIRRORS_COMMAND"

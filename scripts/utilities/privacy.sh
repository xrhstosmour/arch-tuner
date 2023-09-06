#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
PRIVACY_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PRIVACY_SCRIPT_DIRECTORY/../helpers/functions/filesystem.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Array of privacy scripts.
privacy_scripts=(
    $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/network.sh
    $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/keyboard.sh
    $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/umask.sh
)

# Give execution permission to all needed scripts.
give_execution_permission_to_scripts "${privacy_scripts[@]}" "Giving execution permission to all privacy scripts..."

# Configure network.
sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/network.sh

# Install and configure keystroke anonymization.
sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/keyboard.sh

# Configure umask.
sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/umask.sh

# TODO: Implement encrypted swap.

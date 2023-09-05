#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INTERFACE_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$INTERFACE_SCRIPT_DIRECTORY/../helpers/functions.sh"

# Array of interface scripts.
interface_scripts=(
    $INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/display.sh
    $INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/gpu.sh
)

# Give execution permission to all needed scripts.
give_execution_permission_to_scripts "${interface_scripts[@]}" "Giving execution permission to all interface scripts..."

# Install and configure display manager.
sh $INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/display.sh

# Install and configure GPU drivers.
sh $INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/gpu.sh

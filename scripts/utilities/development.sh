#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DEVELOPMENT_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/functions.sh"

# Array of development scripts.
development_scripts=(
    $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/tools.sh
    $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/programming.sh
)

# Give execution permission to all needed scripts.
give_execution_permission_to_scripts "${development_scripts[@]}" "Giving execution permission to all development scripts..."

# Install and configure development tools.
sh $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/tools.sh

# Install and configure programming languages.
sh $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/programming.sh

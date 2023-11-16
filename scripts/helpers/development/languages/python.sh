#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
PYTHON_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PYTHON_SCRIPT_DIRECTORY/../../functions/logs.sh"

# Query the current setting for virtualenvs.in-project.
current_setting=$(poetry config virtualenvs.in-project)

# Check if it's already set to true.
if [[ "$current_setting" != "true" ]]; then
    log_info "Configuring Poetry to create virtual environments in the project directory..."
    poetry config virtualenvs.in-project true
fi

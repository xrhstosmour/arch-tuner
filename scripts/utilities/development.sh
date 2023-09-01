#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SCRIPT_DIRECTORY/../helpers/functions.sh"

# Give execution permission to all needed scripts.
log_info "Giving execution permission to all development scripts..."
chmod +x $SCRIPT_DIRECTORY/../helpers/development/tools.sh
chmod +x $SCRIPT_DIRECTORY/../helpers/development/programming.sh

# Install and configure development tools.
sh $SCRIPT_DIRECTORY/../helpers/development/tools.sh

# Install and configure programming languages.
sh $SCRIPT_DIRECTORY/../helpers/development/programming.sh

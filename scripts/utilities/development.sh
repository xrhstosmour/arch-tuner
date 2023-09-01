#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DEVELOPMENT_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/functions.sh"

# Give execution permission to all needed scripts.
log_info "Giving execution permission to all development scripts..."
chmod +x $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/tools.sh
chmod +x $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/programming.sh

# Install and configure development tools.
sh $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/tools.sh

# Install and configure programming languages.
sh $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/programming.sh

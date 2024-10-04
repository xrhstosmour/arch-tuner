#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DEVELOPMENT_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/functions/filesystem.sh"

# Configure shell for development purposes.
sh $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/shell.sh

# Configure Git.
sh $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/git.sh

# Install and configure software.
sh $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/software.sh

# Install and configure programming languages.
sh $DEVELOPMENT_SCRIPT_DIRECTORY/../helpers/development/programming.sh

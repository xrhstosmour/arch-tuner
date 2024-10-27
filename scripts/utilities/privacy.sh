#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
PRIVACY_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PRIVACY_SCRIPT_DIRECTORY/../helpers/functions/filesystem.sh"
source "$PRIVACY_SCRIPT_DIRECTORY/../helpers/functions/packages.sh"
source "$PRIVACY_SCRIPT_DIRECTORY/../core/flags.sh"

# Configure network.
sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/network.sh

# TODO: There are open issues with the kloak package, so this script is not working properly, and it is not recommended to use for now.
# Install and configure keystroke anonymization.
# sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/keyboard.sh

# Configure umask.
sh $PRIVACY_SCRIPT_DIRECTORY/../helpers/privacy/umask.sh

# TODO: Implement encrypted swap.

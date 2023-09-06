#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INTERFACE_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$INTERFACE_SCRIPT_DIRECTORY/../helpers/functions/filesystem.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Install and configure display manager.
sh $INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/display.sh

# TODO: Restart device to apply changes and rerun script.

# Install and configure GPU drivers.
sh $INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/gpu.sh

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
NETWORK_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$NETWORK_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$NETWORK_SCRIPT_DIRECTORY/../functions/services.sh"

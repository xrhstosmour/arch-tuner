#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SETTINGS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Enable and start bluetooth services.
sh $SETTINGS_SCRIPT_DIRECTORY/settings/bluetooth.sh

# Configure hibernation settings.
sh $SETTINGS_SCRIPT_DIRECTORY/settings/hibernation.sh

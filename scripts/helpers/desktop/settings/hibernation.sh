#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
HIBERNATION_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$HIBERNATION_SCRIPT_DIRECTORY/../../functions/services.sh"
source "$HIBERNATION_SCRIPT_DIRECTORY/../../functions/filesystem.sh"

# Constant variables for hibernation configuration.
HIBERNATION_CONFIGURATION="/etc/systemd/logind.conf"
HIBERNATION_HANDLE_LID_SWITCH_CONFIGURATION="HandleLidSwitch="
HIBERNATION_HANDLE_LID_SWITCH_DOCKED_CONFIGURATION="HandleLidSwitchDocked="
HIBERNATION_IGNORE_CONFIGURATION="ignore"
SYSTEM_D_SERVICE="systemd-logind"

# Configure hibernation via `HandleLidSwitch` and `HandleLidSwitchDocked` variables.
change_configuration "$HIBERNATION_HANDLE_LID_SWITCH_CONFIGURATION" "$HIBERNATION_IGNORE_CONFIGURATION" "$HIBERNATION_CONFIGURATION"
change_configuration "$HIBERNATION_HANDLE_LID_SWITCH_DOCKED_CONFIGURATION" "$HIBERNATION_IGNORE_CONFIGURATION" "$HIBERNATION_CONFIGURATION"

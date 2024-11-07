#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
GREETER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$GREETER_SCRIPT_DIRECTORY/../functions/filesystem.sh"
source "$GREETER_SCRIPT_DIRECTORY/../functions/ui.sh"

# Ask user to install and configure a greeter.
user_answer=$(ask_user_before_execution "Would you like to install a login greeter?" "false" "$GREETER_SCRIPT_DIRECTORY/../interface/greeters/ly.sh")

# TODO: Add a password dialog manager like `plymouth`. Help here: https://srijan.ch/graphical-password-prompt-for-disk-decryption

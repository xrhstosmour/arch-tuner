#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INTERFACE_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source "$INSTALL_SCRIPT_DIRECTORY/../helpers/functions/ui.sh"

# Install and configure greeter.
user_answer=$(ask_user_before_execution "Would you like to install a greeter?" "true" "$INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/greeter.sh")

# Install and configure GPU drivers.
sh $INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/gpu.sh

# Install dotfiles from existing repository.
sh $INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/dotfiles.sh

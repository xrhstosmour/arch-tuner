#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DESKTOP_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Install and configure GPU drivers.
sh $DESKTOP_SCRIPT_DIRECTORY/../helpers/desktop/gpu.sh

# Install dotfiles from existing repository.
sh $DESKTOP_SCRIPT_DIRECTORY/../helpers/desktop/dotfiles.sh

# TODO: Create a function to configure system like the following:
# TODO:     - Suspend when lid is closed: https://www.reddit.com/r/archlinux/comments/2d2btn/configuring_suspend_when_lid_closes/

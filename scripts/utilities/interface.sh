#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INTERFACE_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$INTERFACE_SCRIPT_DIRECTORY/../helpers/functions/filesystem.sh"
source "$INTERFACE_SCRIPT_DIRECTORY/../helpers/functions/ui.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Get the user's choice about display manager.
display_manager=$(choose_display_manager)

# Execute the corresponding script
case $display_manager in
ly)
    # Install and configure greeter.
    sh $INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/display_managers/ly.sh
    ;;
sddm)
    # TODO: Implement sddm installation & configuration.
    log_warning "Configuration for sddm display manager is not implemented yet!"
    ;;
esac

# Install and configure GPU drivers.
sh $INTERFACE_SCRIPT_DIRECTORY/../helpers/interface/gpu.sh

# TODO: Install environment packages.
# TODO: Install dotfiles from existing repository.

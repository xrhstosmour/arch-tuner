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

# Get the user's choice about greeter.
declare -a DISPLAY_OPTIONS=("ly" "sddm")
display_manager=$(choose_option "Choose a greeter" "${DISPLAY_OPTIONS[@]}")

# Execute the corresponding script
case $display_manager in
ly)
    # Install and configure greeter.
    sh $GREETER_SCRIPT_DIRECTORY/../interface/greeters/ly.sh
    ;;
sddm)
    # TODO: Implement `sddm` installation & configuration.
    log_warning "Configuration for sddm greeter is not implemented yet!"
    ;;
gdm)
    # TODO: Implement `gdm` installation & configuration.
    log_warning "Configuration for gdm greeter is not implemented yet!"
    ;;
esac

# TODO: Add a password dialog manager like `plymouth`.

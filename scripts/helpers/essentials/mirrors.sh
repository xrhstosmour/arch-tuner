#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
MIRRORS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions and flags.
source "$MIRRORS_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$MIRRORS_SCRIPT_DIRECTORY/../functions/filesystem.sh"
source "$MIRRORS_SCRIPT_DIRECTORY/../functions/services.sh"
source "$MIRRORS_SCRIPT_DIRECTORY/../../core/flags.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variables for changing and configuring shell.
REFLECTOR_DIRECTORY="/etc/xdg/reflector/"
REFLECTOR_CONFIGURATION="/etc/xdg/reflector/reflector.conf"
REFLECTOR_CONFIGURATION_TO_PASS="$MIRRORS_SCRIPT_DIRECTORY/../../configurations/mirrors/reflector.conf"

# Install mirror list manager.
install_packages "reflector" "$ARCH_PACKAGE_MANAGER" "Installing mirror list manager..."

# Copy the configuration file only if it is not the same as the current one.
are_reflector_files_the_same=$(compare_files "$REFLECTOR_CONFIGURATION" "$REFLECTOR_CONFIGURATION_TO_PASS")
if [ "$are_reflector_files_the_same" = "false" ]; then
    log_info "Configuring mirror list..."
    sudo mkdir -p "$REFLECTOR_DIRECTORY"
    sudo cp -f "$REFLECTOR_CONFIGURATION_TO_PASS" "$REFLECTOR_CONFIGURATION"

    # Read the configuration file into a string, excluding comment lines.
    args=$(grep -v '^#' "$REFLECTOR_CONFIGURATION")

    # Run reflector with the arguments.
    sudo reflector ${args} >/dev/null
fi

# Before enabling the service, check if it is already enabled and keep it for later use.
is_reflector_already_enabled=$(is_service_enabled "reflector")

# Enable and start mirror list service if they are not already active.
enable_service "reflector" "Enabling mirror list auto refresh service..."

# Run reflector once to populate the mirror list.
# The reflector service will show as inactive and run periodically, with the help of the reflector timer.
if [[ "$is_reflector_already_enabled" = "false" ]] || [[ "$INITIAL_SETUP" -eq 0 ]]; then
    start_service "reflector" "Running mirror list auto refresh service..."
fi

# Start and enable mirror list timer if they are not already active.
start_service "reflector.timer" "Starting mirror list auto refresh timer service..."
enable_service "reflector.timer" "Enabling mirror list auto refresh timer service..."

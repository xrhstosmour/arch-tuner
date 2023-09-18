#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
PROGRAMMING_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PROGRAMMING_SCRIPT_DIRECTORY/../functions/packages.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variable for the file path containing the programming languages to install.
PROGRAMMING_LANGUAGES="$PROGRAMMING_SCRIPT_DIRECTORY/../../packages/development/programming.txt"

# Check if at least one programming language package is not installed.
are_programming_packages_installed=$(are_packages_installed "$PROGRAMMING_LANGUAGES" "$AUR_PACKAGE_MANAGER")
if [ "$are_programming_packages_installed" = "false" ]; then
    log_info "Installing programming languages..."

    # Install programming languages packages.
    install_packages "$PROGRAMMING_LANGUAGES" "$AUR_PACKAGE_MANAGER"
fi

# ! PYTHON SECTION.
# Configure Python poetry.
if grep -q "^python-poetry$" "$PROGRAMMING_LANGUAGES"; then

    # Query the current setting for virtualenvs.in-project.
    current_setting=$(poetry config virtualenvs.in-project)

    # Check if it's already set to true.
    if [[ "$current_setting" != "true" ]]; then
        log_info "Configuring Poetry to create virtual environments in the project directory..."
        poetry config virtualenvs.in-project true
    fi
fi

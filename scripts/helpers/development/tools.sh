#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
TOOLS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions variables.
source "$TOOLS_SCRIPT_DIRECTORY/../functions.sh"

# Constant variable for the file path containing the development tools to install.
DEVELOPMENT_TOOLS="$TOOLS_SCRIPT_DIRECTORY/../../packages/development.txt"

# Check if at least one development package is not installed.
if ! are_packages_installed "$DEVELOPMENT_TOOLS" "$AUR_PACKAGE_MANAGER"; then
    log_info "Installing development tools..."

    # Install development packages.
    install_packages "$DEVELOPMENT_TOOLS" "$AUR_PACKAGE_MANAGER"
fi

# ! DOCKER SECTION.
# Configure Docker.
if grep -q "^docker$" "$DEVELOPMENT_TOOLS"; then

    # Enable Docker service.
    enable_service "docker"

    # Start Docker service.
    start_service "docker"
fi

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SOFTWARE_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SOFTWARE_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$SOFTWARE_SCRIPT_DIRECTORY/../functions/services.sh"
source "$SOFTWARE_SCRIPT_DIRECTORY/../../core/flags.sh"

# Install only if the user chooses to install an interface.
if [ $INTERFACE_COMPLETED -eq 0 ]; then

    # Constant variable for the file path containing the development applications to install.
    DEVELOPMENT_APPLICATIONS="$SOFTWARE_SCRIPT_DIRECTORY/../../packages/development/applications.txt"

    # Check if at least one development application package is not installed.
    are_development_application_packages_installed=$(are_packages_installed "$DEVELOPMENT_APPLICATIONS" "$AUR_PACKAGE_MANAGER")
    if [ "$are_development_application_packages_installed" = "false" ]; then
        log_info "Installing development applications..."

        # Install development application packages.
        install_packages "$DEVELOPMENT_APPLICATIONS" "$AUR_PACKAGE_MANAGER"
    fi
fi

# Constant variable for the file path containing the software tools to install.
SOFTWARE_TOOLS="$SOFTWARE_SCRIPT_DIRECTORY/../../packages/development/tools.txt"

# Check if at least one software tool package is not installed.
are_software_tool_packages_installed=$(are_packages_installed "$SOFTWARE_TOOLS" "$AUR_PACKAGE_MANAGER")
if [ "$are_software_tool_packages_installed" = "false" ]; then
    log_info "Installing software tools..."

    # Install software tool packages.
    install_packages "$SOFTWARE_TOOLS" "$AUR_PACKAGE_MANAGER"
fi

# ! DOCKER SECTION.
if grep -q "^docker$" "$SOFTWARE_TOOLS"; then

    # Install and configure Docker.
    sh $SOFTWARE_SCRIPT_DIRECTORY/tools/docker.sh
fi

# ! MISE SECTION.
if grep -q "^mise-bin$" "$SOFTWARE_TOOLS"; then

    # Install and configure mise.
    sh $SOFTWARE_SCRIPT_DIRECTORY/tools/mise.sh
fi

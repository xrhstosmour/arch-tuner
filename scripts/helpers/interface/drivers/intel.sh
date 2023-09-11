#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INTEL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$INTEL_SCRIPT_DIRECTORY/../../functions/packages.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# TODO: Check if this is working or not.
# Constant variable containing the Intel graphics drivers.
INTEL_COMMON_DRIVERS="xf86-video-intel vulkan-intel"
INTEL_32_BIT_DRIVERS="lib32-mesa lib32-mesa-amber lib32-vulkan-intel"

# Keep the INTEL GPU generation in a variable, to use it later.
GENERATION=$(lspci -k | grep -A 2 -E "(VGA|3D)" | grep 'Intel Corporation' | grep 'Generation Core Processor Family Integrated Graphics Controller')
if [[ $GENERATION =~ ([0-9]+) ]]; then
    GENERATION_NUMBER=${BASH_REMATCH[1]}
    if ((GENERATION_NUMBER <= 7)); then

        # Constant variable containing the INTEL graphics drivers for 7th generation and older support.
        INTEL_7TH_AND_OLDER_DRIVERS="mesa-amber"

        # Check if at least one INTEL graphics driver is not installed.
        are_intel_7th_and_older_drivers_installed=$(are_packages_installed "$INTEL_7TH_AND_OLDER_DRIVERS" "$AUR_PACKAGE_MANAGER")
        if [ "$are_intel_7th_and_older_drivers_installed" = "false" ]; then
            log_info "Installing INTEL drivers..."
        fi

        # Install the appropriate INTEL graphics driver.
        install_packages "$INTEL_7TH_AND_OLDER_DRIVERS" "$AUR_PACKAGE_MANAGER" "Installing INTEL drivers for 7th generation and older support..."
    else

        # Constant variable containing the INTEL graphics drivers for 8th generation and newer support.
        INTEL_8TH_AND_NEWER_DRIVERS="mesa"

        # Check if at least one INTEL graphics driver is not installed.
        are_intel_8th_and_newer_drivers_installed=$(are_packages_installed "$INTEL_8TH_AND_NEWER_DRIVERS" "$AUR_PACKAGE_MANAGER")
        if [ "$are_intel_8th_and_newer_drivers_installed" = "false" ]; then
            log_info "Installing INTEL drivers..."
        fi

        # Install the appropriate INTEL graphics driver.
        install_packages "$INTEL_8TH_AND_NEWER_DRIVERS" "$AUR_PACKAGE_MANAGER" "Installing INTEL drivers for 8th generation and newer support..."
    fi
else
    log_warning "No valid INTEL GPU found or the generation format is not valid!"
fi

# Proceed with the installation of common INTEL drivers.
install_packages "$INTEL_COMMON_DRIVERS" "$AUR_PACKAGE_MANAGER" "Installing INTEL common drivers..."

# Intalling INTEL drivers for 32-bit support.
install_packages "$INTEL_32_BIT_DRIVERS" "$AUR_PACKAGE_MANAGER" "Installing INTEL drivers for 32-bit support..."

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
INTEL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$INTEL_SCRIPT_DIRECTORY/../../functions/packages.sh"

# Constant variable containing the Intel graphics drivers.
INTEL_COMMON_DRIVERS="xf86-video-intel vulkan-intel"

log_info "Installing INTEL drivers..."

# Get the Intel GPU generation.
GENERATION=$(lspci -k | grep -A 2 -E "(VGA|3D)" | grep 'Intel Corporation' | grep 'Generation Core Processor Family Integrated Graphics Controller' | grep -oP '[0-9]+' || echo "")

# Determine and install the appropriate drivers based on the GPU generation.
if [[ "$GENERATION" =~ ^[0-9]+$ ]] && [ "$GENERATION" -le 7 ]; then
    install_packages "mesa-amber" "$AUR_PACKAGE_MANAGER" "Installing INTEL drivers for 7th generation and older support..."
else
    install_packages "mesa" "$AUR_PACKAGE_MANAGER" "Installing INTEL drivers for 8th generation and newer support..."
fi

# Proceed with the installation of common INTEL drivers.
install_packages "$INTEL_COMMON_DRIVERS" "$AUR_PACKAGE_MANAGER" "Installing INTEL common drivers..."

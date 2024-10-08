#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
AMD_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$AMD_SCRIPT_DIRECTORY/../../functions/packages.sh"

# TODO: Check if this is working or not.
# Constant variable containing the AMD graphics drivers.
AMD_DRIVERS="mesa-git xf86-video-amdgpu-git vulkan-radeon libva-mesa-driver mesa-vdpau"

# Install AMD drivers.
install_packages "$AMD_DRIVERS" "$AUR_PACKAGE_MANAGER" "Installing AMD drivers..."

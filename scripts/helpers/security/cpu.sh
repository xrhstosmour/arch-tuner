#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
CPU_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$CPU_SCRIPT_DIRECTORY/../functions.sh"

# Initialize a flag indicating if a microcode update was installed.
cpu_update_installed=1

# Constant variables containing the cpu manufacturer names and their respective microcode packages.
INTEL_MANUFACTURER="GenuineIntel"
INTEL_CPU_UPDATES="intel-ucode"
AMD_MANUFACTURER="AuthenticAMD"
AMD_CPU_UPDATES="amd-ucode"

# Get the CPU manufacturer.
cpu_manufacturer=$(grep -m 1 -oP 'vendor_id\s*:\s*\K.*' /proc/cpuinfo)

# Install the appropriate CPU updates based on the CPU manufacturer.
if [[ $cpu_manufacturer == *"$INTEL_MANUFACTURER"* ]]; then

    # Install Intel CPU updates.
    if ! are_packages_installed "$INTEL_CPU_UPDATES" "$AUR_PACKAGE_MANAGER"; then
        install_packages "$INTEL_CPU_UPDATES" "$AUR_PACKAGE_MANAGER" "Installing Intel CPU updates..."

        # Set the cpu_update_installed flag to 0 (true).
        cpu_update_installed=0
    fi
elif [[ $cpu_manufacturer == *"$AMD_MANUFACTURER"* ]]; then

    # Install AMD CPU updates.
    if ! are_packages_installed "$AMD_CPU_UPDATES" "$AUR_PACKAGE_MANAGER"; then
        install_packages "$AMD_CPU_UPDATES" "$AUR_PACKAGE_MANAGER" "Installing AMD CPU updates..."

        # Set the cpu_update_installed flag to 0 (true).
        cpu_update_installed=0
    fi
fi

# Update grub to apply CPU updates at boot.
if [ $cpu_update_installed -eq 0 ]; then
    log_info "Applying CPU updates..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
GPU_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$GPU_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$GPU_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Get an array of GPU vendors.
readarray -t VENDORS < <(lspci -v -m | grep -A1 VGA | grep Vendor | awk "{print \$2}" | tr "[:upper:]" "[:lower:]")

# Loop through the array of GPU vendors and handle each one.
for VENDOR in "${VENDORS[@]}"; do
    case "$VENDOR" in
    "nvidia")
        # Install NVIDIA drivers.
        sh $GPU_SCRIPT_DIRECTORY/drivers/nvidia.sh
        ;;

    "amd")
        # Install AMD drivers.
        sh $GPU_SCRIPT_DIRECTORY/drivers/amd.sh
        ;;

    "intel")
        # Install INTEL drivers.
        sh $GPU_SCRIPT_DIRECTORY/drivers/intel.sh
        ;;

    *)
        # Install default drivers.
        install_packages "mesa" "$AUR_PACKAGE_MANAGER" "Installing default drivers..."
        ;;
    esac
done

# Additional handling if inside a virtual machine.
VIRTUAL_MACHINE=$(systemd-detect-virt || true)
case "$VIRTUAL_MACHINE" in
"vmware")
    # Install VMWARE drivers and configure open VM tools.
    sh $GPU_SCRIPT_DIRECTORY/drivers/vmware.sh
    ;;

"oracle")

    # TODO: Install VirtualBox drivers.
    log_warning "No valid VirtualBox drivers found!"
    ;;

*)
    ;;
esac

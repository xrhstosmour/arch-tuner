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

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Array of GPU scripts.
gpu_scripts=(
    $GPU_SCRIPT_DIRECTORY/drivers/nvidia.sh
    $GPU_SCRIPT_DIRECTORY/drivers/amd.sh
    $GPU_SCRIPT_DIRECTORY/drivers/intel.sh
    $GPU_SCRIPT_DIRECTORY/drivers/vmware.sh
)

# Give execution permission to all needed scripts.
give_execution_permission_to_scripts "${gpu_scripts[@]}" "Giving execution permission to all GPU scripts..."

# TODO: Check if this is working or not.
# Get an array of GPU vendors.
readarray -t VENDORS < <(lspci -v -m | grep -A1 VGA | grep SVendor | awk "{print \$2}" | tr "[:upper:]" "[:lower:]")

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
VIRTUAL_MACHINE=$(systemd-detect-virt)
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
    # TODO: Possibly handle other virtual machines here.
    log_warning "No valid $VIRTUAL_MACHINE drivers found!"
    ;;
esac

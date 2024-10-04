#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
NVIDIA_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$NVIDIA_SCRIPT_DIRECTORY/../../functions/packages.sh"

log_info "Installing NVIDIA drivers..."

# Keep the linux kernel header in a variable, to use it later.
KERNEL=$(cat /usr/lib/modules/*/pkgbase)
CODE_NAME=$(lspci -k | grep -A 2 -E "(VGA|3D)" | grep 'NVIDIA Corporation')

# Install the appropriate linux kernel headers and NVIDIA drivers.
install_packages "$KERNEL-headers" "$AUR_PACKAGE_MANAGER" "Installing $KERNEL headers..."
install_packages "libva-nvidia-driver " "$AUR_PACKAGE_MANAGER"

case "$CODE_NAME" in
# If the NVIDIA family is Maxwell, card's code name includes NV110/GMXXX:
# install nvidia for linux kernel
# install nvidia-lts for linux-lts kernel
# install nvidia-dkms for all the other kernels
*NV110* | *GM*)

    # Install the appropriate NVIDIA Maxwell graphics driver.
    if [[ "$KERNEL" == "linux" ]]; then
        install_packages "nvidia" "$AUR_PACKAGE_MANAGER" "Installing NVIDIA Maxwell drivers..."
    elif [[ "$KERNEL" == "linux-lts" ]]; then
        install_packages "nvidia-lts" "$AUR_PACKAGE_MANAGER" "Installing NVIDIA Maxwell drivers..."
    else
        install_packages "nvidia-dkms" "$AUR_PACKAGE_MANAGER" "Installing NVIDIA Maxwell drivers..."
    fi
    ;;

# If the NVIDIA family is Turing, card's code name includes NV160/TUXXX:
# install nvidia-open for linux kernel
# install nvidia-open-dkms for all the other kernels
*NV160* | *TU*)

    # Install the appropriate NVIDIA Turing graphics driver.
    if [[ "$KERNEL" == "linux" ]]; then
        install_packages "nvidia-open" "$AUR_PACKAGE_MANAGER" "Installing NVIDIA Turing drivers..."
    else
        install_packages "nvidia-open-dkms" "$AUR_PACKAGE_MANAGER" "Installing NVIDIA Turing drivers..."
    fi
    ;;

# If the NVIDIA family is Kepler, card's code name includes NVE0/GKXXX:
# install nvidia-470xx-dkms
*NVE0* | *GK*)

    # Install the appropriate NVIDIA Kepler graphics driver.
    install_packages "nvidia-470xx-dkms" "$AUR_PACKAGE_MANAGER" "Installing NVIDIA Kepler drivers..."
    ;;

*) ;;
esac

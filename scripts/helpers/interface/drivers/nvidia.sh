#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
NVIDIA_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$NVIDIA_SCRIPT_DIRECTORY/../../functions/packages.sh"
source "$NVIDIA_SCRIPT_DIRECTORY/../../functions/services.sh"

# TODO: Check if this is working or not.
# Constant variable containing the NVIDIA 32 bit graphics drivers.
NVIDIA_32_BIT_DRIVERS="lib32-nvidia-libgl lib32-nvidia-utils"

# Keep the linux kernel header in a variable, to use it later.
KERNEL=$(cat /usr/lib/modules/*/pkgbase)
CODE_NAME=$(lspci -k | grep -A 2 -E "(VGA|3D)")

# Install the appropriate linux kernel headers.
install_packages "$KERNEL-headers" "$AUR_PACKAGE_MANAGER" "Installing $KERNEL headers..."

case "$CODE_NAME" in
# If the NVIDIA family is Maxwell, card's code name includes NV110/GMXXX:
# install nvidia for linux kernel
# install nvidia-lts for linux-lts kernel
# install nvidia-dkms for all the other kernels
*NV110* | *GM*)

    # Constant variable containing all the NVIDIA Maxwell graphics drivers.
    NVIDIA_MAXWELL_DRIVERS="nvidia nvidia-lts nvidia-dkms"

    # Check if at least one NVIDIA Maxwell graphics driver is not installed.
    are_nvidia_maxwell_drivers_installed=$(are_packages_installed "$NVIDIA_MAXWELL_DRIVERS" "$AUR_PACKAGE_MANAGER")
    if [ "$are_nvidia_maxwell_drivers_installed" = "false" ]; then
        log_info "Installing NVIDIA drivers..."
    fi

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

    # Constant variable containing all the NVIDIA Turing graphics drivers.
    NVIDIA_TURING_DRIVERS="nvidia-open nvidia-open-dkms"

    # Check if at least one NVIDIA Turing graphics driver is not installed.
    are_nvidia_turing_drivers_installed=$(are_packages_installed "$NVIDIA_TURING_DRIVERS" "$AUR_PACKAGE_MANAGER")
    if [ "$are_nvidia_turing_drivers_installed" = "false" ]; then
        log_info "Installing NVIDIA drivers..."
    fi

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

    # Constant variable containing all the NVIDIA Kepler graphics drivers.
    NVIDIA_KEPLER_DRIVERS="nvidia-470xx-dkms"

    # Check if at least one NVIDIA Kepler graphics driver is not installed.
    are_nvidia_kepler_drivers_installed=$(are_packages_installed "$NVIDIA_KEPLER_DRIVERS" "$AUR_PACKAGE_MANAGER")
    if [ "$are_nvidia_kepler_drivers_installed" = "false" ]; then
        log_info "Installing NVIDIA drivers..."
    fi

    # Install the appropriate NVIDIA Kepler graphics driver.
    install_packages "nvidia-470xx-dkms" "$AUR_PACKAGE_MANAGER" "Installing NVIDIA Kepler drivers..."
    ;;

*)
    log_warning "Unsupported NVIDIA family!"
    ;;
esac

# Intalling NVIDIA drivers for 32-bit support.
install_packages "$NVIDIA_32_BIT_DRIVERS" "$AUR_PACKAGE_MANAGER" "Installing NVIDIA drivers for 32-bit support..."

# Enable persistence mode.
start_service "nvidia-persistenced" "Starting persistence mode..."
enable_service "nvidia-persistenced" "Enabling persistence mode..."

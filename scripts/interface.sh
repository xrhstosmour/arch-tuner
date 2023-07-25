#!/bin/bash

# Color for the script's messages.
CYAN='\033[1;36m'
NO_COLOR='\033[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Installing the display manager.
echo -e "\n${CYAN}Installing display manager...${NO_COLOR}"
paru -S --noconfirm --needed ly-git

# Configuring the display manager.
echo -e "\n${CYAN}Configuring display manager...${NO_COLOR}"
sudo systemctl enable ly
sudo sed -i '/^#.*blank_password/s/^#//' /etc/ly/config.ini

# Installing GPU drivers per vendor.
VENDOR=$(lspci -v -m | grep -A1 VGA | grep SVendor | awk "{print \$2}" | tr "[:upper:]" "[:lower:]")

case $VENDOR in
"nvidia")
    echo -e "\n${CYAN}Installing NVIDIA drivers...${NO_COLOR}"

    # Keep the linux kernel header in a variable, to use it later.
    KERNEL=$(cat /usr/lib/modules/*/pkgbase)
    CODE_NAME=$(lspci -k | grep -A 2 -E "(VGA|3D)")

    # Installing the appropriate linux kernel headers.
    echo -e "\n${CYAN}Installing $KERNEL headers...${NO_COLOR}"
    paru -S --noconfirm --needed $KERNEL-headers

    case "$CODE_NAME" in
    # If the NVIDIA family is Maxwell, card's code name includes NV110/GMXXX:
    # install nvidia for linux kernel
    # install nvidia-lts for linux-lts kernel
    # install nvidia-dkms for all the other kernels
    *NV110* | *GM*)
        echo -e "\n${CYAN}Installing NVIDIA Maxwell drivers...${NO_COLOR}"
        if [[ "$KERNEL" == "linux" ]]; then
            paru -S --noconfirm --needed nvidia
        elif [[ "$KERNEL" == "linux-lts" ]]; then
            paru -S --noconfirm --needed nvidia-lts
        else
            paru -S --noconfirm --needed nvidia-dkms
        fi
        ;;

    # If the NVIDIA family is Turing, card's code name includes NV160/TUXXX:
    # install nvidia-open for linux kernel
    # install nvidia-open-dkms for all the other kernels
    *NV160* | *TU*)
        echo -e "\n${CYAN}Installing NVIDIA Turing drivers...${NO_COLOR}"
        if [[ "$KERNEL" == "linux" ]]; then
            paru -S --noconfirm --needed nvidia-open
        else
            paru -S --noconfirm --needed nvidia-open-dkms
        fi
        ;;

    # If the NVIDIA family is Kepler, card's code name includes NVE0/GKXXX:
    # install nvidia-470xx-dkms
    *NVE0* | *GK*)
        echo -e "\n${CYAN}Installing NVIDIA Kepler drivers...${NO_COLOR}"
        paru -S --noconfirm --needed nvidia-470xx-dkms
        ;;

    *)
        echo "Unsupported NVIDIA family."
        ;;
    esac

    # Intalling NVIDIA drivers for 32-bit support.
    echo -e "\n${CYAN}Installing NVIDIA drivers for 32-bit support...${NO_COLOR}"
    paru -S --noconfirm --needed lib32-nvidia-libgl lib32-nvidia-utils

    # Enabling persistence mode.
    echo -e "\n${CYAN}Enabling persistence mode...${NO_COLOR}"
    if systemctl list-units --full --all | grep -Fq 'nvidia-persistenced.service'; then
        sudo systemctl enable nvidia-persistenced.service
        sudo systemctl start nvidia-persistenced.service
    fi

    ;;

"amd")
    echo -e "\n${CYAN}Installing AMD drivers...${NO_COLOR}"
    paru -S --noconfirm --needed mesa-git xf86-video-amdgpu-git vulkan-radeon \
        libva-mesa-driver mesa-vdpau

    # Intalling AMD drivers for 32-bit support.
    echo -e "\n${CYAN}Installing AMD drivers for 32-bit support...${NO_COLOR}"
    paru -S --noconfirm --needed lib32-mesa-git lib32-mesa-vdpau lib32-vulkan-radeon \
        lib32-libva-mesa-driver
    ;;

"intel")
    # TODO: Check if this is the correct way to install Intel drivers.
    echo -e "\n${CYAN}Installing Intel drivers...${NO_COLOR}"
    paru -S --noconfirm --needed mesa mesa-amber xf86-video-intel vulkan-intel

    # Intalling Intel drivers for 32-bit support.
    echo -e "\n${CYAN}Installing Intel drivers for 32-bit support...${NO_COLOR}"
    paru -S --noconfirm --needed lib32-mesa lib32-mesa-amber lib32-vulkan-intel

    ;;

"vmware")
    echo -e "\n${CYAN}Installing VMware drivers...${NO_COLOR}"
    paru -S --noconfirm --needed mesa

    # Installing Open VM Tools.
    echo -e "\n${CYAN}Installing Open VM Tools...${NO_COLOR}"
    paru -S --noconfirm --needed open-vm-tools xf86-input-vmmouse \
        xf86-video-vmware gtkmm
    sudo echo needs_root_rights=yes >>/etc/X11/Xwrapper.config
    sudo systemctl enable vmtoolsd && sudo systemctl start vmtoolsd
    ;;

*)
    echo -e "\n${CYAN}Installing default drivers...${NO_COLOR}"
    paru -S --noconfirm --needed mesa
    ;;
esac

#!/bin/bash

# Color for the script's messages.
BOLD_CYAN='\e[1;36m'
NO_COLOR='\e[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Installing firewall and antivirus.
echo -e "\n${BOLD_CYAN}Installing firewall...${NO_COLOR}"
paru -S --noconfirm --needed ufw iptables

# Configuring firewall.
echo -e "\n${BOLD_CYAN}Configuring firewall...${NO_COLOR}"
sudo systemctl start ufw
sudo systemctl enable ufw
sudo ufw default allow outgoing
sudo ufw default deny incoming

# Enabling firewall.
echo -e "\n${BOLD_CYAN}Enabling firewall...${NO_COLOR}"
echo "y" | sudo ufw enable
sudo ufw reload

# Installing antivirus.
echo -e "\n${BOLD_CYAN}Installing antivirus...${NO_COLOR}"
paru -S --noconfirm --needed clamav

# Configuring antivirus.
echo -e "\n${BOLD_CYAN}Configuring antivirus...${NO_COLOR}"
sudo systemctl stop clamav-freshclam
sudo freshclam

# Creating quarantine folder.
echo -e "\n${BOLD_CYAN}Creating quarantine folder...${NO_COLOR}"
sudo mkdir -p /qrntn
sudo chown -R clamav:clamav /qrntn
sudo chmod -R 750 /qrntn

# Configuring real-time scanning.
echo -e "\n${BOLD_CYAN}Configuring real-time scanning...${NO_COLOR}"
grep -qxF 'OnAccessPrevention Yes' /etc/clamav/clamd.conf || echo 'OnAccessPrevention Yes' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessIncludePath /' /etc/clamav/clamd.conf || echo 'OnAccessIncludePath /' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessExcludeUname clamav' /etc/clamav/clamd.conf || echo 'OnAccessExcludeUname clamav' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessExcludePath /proc' /etc/clamav/clamd.conf || echo 'OnAccessExcludePath /proc' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessExcludePath /sys' /etc/clamav/clamd.conf || echo 'OnAccessExcludePath /sys' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessExcludePath /dev' /etc/clamav/clamd.conf || echo 'OnAccessExcludePath /dev' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessExcludePath /run' /etc/clamav/clamd.conf || echo 'OnAccessExcludePath /run' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessExcludePath /tmp' /etc/clamav/clamd.conf || echo 'OnAccessExcludePath /tmp' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessExcludePath /qrntn' /etc/clamav/clamd.conf || echo 'OnAccessExcludePath /qrntn' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessExcludePath /var/tmp' /etc/clamav/clamd.conf || echo 'OnAccessExcludePath /var/tmp' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessExcludePath /var/run' /etc/clamav/clamd.conf || echo 'OnAccessExcludePath /var/run' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'OnAccessExcludePath /var/lock' /etc/clamav/clamd.conf || echo 'OnAccessExcludePath /var/lock' | sudo tee -a /etc/clamav/clamd.conf >/dev/null
grep -qxF 'User clamav' /etc/clamav/clamd.conf || echo 'User clamav' | sudo tee -a /etc/clamav/clamd.conf >/dev/null

# Enabling antivirus.
echo -e "\n${BOLD_CYAN}Enabling antivirus...${NO_COLOR}"
sudo systemctl start clamav-freshclam.service
sudo systemctl enable clamav-freshclam.service
sudo systemctl start clamav-daemon.service
sudo systemctl enable clamav-daemon.service

# Enabling real-time scanning.
echo -e "\n${BOLD_CYAN}Enabling real-time scanning...${NO_COLOR}"
sudo clamonacc --move=/qrntn

# Check if NetworkManager is installed and running.
if command -v NetworkManager >/dev/null && systemctl is-active --quiet NetworkManager; then

    # Check if the settings are already set to reduce trackability.
    if ! grep -q "wifi.scan-rand-mac-address=yes" /etc/NetworkManager/conf.d/00-macrandomize.conf ||
        ! grep -q "wifi.cloned-mac-address=random" /etc/NetworkManager/conf.d/00-macrandomize.conf ||
        ! grep -q "ethernet.cloned-mac-address=random" /etc/NetworkManager/conf.d/00-macrandomize.conf; then

        # Enabling trackability reduction.
        echo -e "\n${BOLD_CYAN}Enabling trackability reduction...${NO_COLOR}"

        # Create or overwrite the configuration file with the desired settings
        echo -e "[device]\nwifi.scan-rand-mac-address=yes\n\n[connection]\nwifi.cloned-mac-address=random\nethernet.cloned-mac-address=random" | sudo tee /etc/NetworkManager/conf.d/00-macrandomize.conf >/dev/null

        # Restart the NetworkManager service to apply the changes
        systemctl restart NetworkManager
    fi
fi

# Installing keystroke anonymization.
echo -e "\n${BOLD_CYAN}Installing keystroke anonymization...${NO_COLOR}"
paru -S --noconfirm --needed kloak-git

# Get the CPU manufacturer.
cpu_manufacturer=$(grep -m 1 -oP 'vendor_id\s*:\s*\K.*' /proc/cpuinfo)

# Initialize a flag indicating if a microcode update was installed.
update_installed=false

# Install the appropriate microcode based on the CPU manufacturer.
if [[ $cpu_manufacturer == *'GenuineIntel'* ]]; then
    echo -e "\n${BOLD_CYAN}Installing Intel microcode updates...${NO_COLOR}"
    sudo pacman -S --noconfirm --needed intel-ucode
    update_installed=true
elif [[ $cpu_manufacturer == *'AuthenticAMD'* ]]; then
    echo -e "\n${BOLD_CYAN}Installing AMD microcode updates...${NO_COLOR}"
    sudo pacman -S --noconfirm --needed amd-ucode
    update_installed=true
fi

# Update grub to apply microcode updates at boot, only if an update was installed.
if $update_installed; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# Installing hardened memory allocator.
echo -e "\n${BOLD_CYAN}Installing hardened memory allocator...${NO_COLOR}"
paru -S --noconfirm --needed hardened_malloc

# Enabling hardened memory allocator.
echo -e "\n${BOLD_CYAN}Enabling hardened memory allocator...${NO_COLOR}"
echo 'LD_PRELOAD=/usr/lib/libhardened_malloc.so' | sudo tee -a /etc/environment >/dev/null

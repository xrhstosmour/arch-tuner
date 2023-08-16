#!/bin/bash

# Import constant variables, signal handlers and functions.
source ./constants.sh
source ./signals.sh
source ./functions.sh

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

# Check if keystroke anonymization is installed, if not install it.
if ! paru -Qq | grep -q '^kloak-git$'; then

    # Installing keystroke anonymization.
    echo -e "\n${BOLD_CYAN}Installing keystroke anonymization...${NO_COLOR}"
    paru -S --noconfirm --needed kloak-git

    # Create a systemd service to run kloak at startup.
    echo -e "\n${BOLD_CYAN}Configuring keystroke anonymization...${NO_COLOR}"
    echo "[Unit]
    Description=Keystroke-level Online Anonymization Kernel

    [Service]
    ExecStart=/usr/bin/kloak

    [Install]
    WantedBy=multi-user.target" | sudo tee /etc/systemd/system/kloak.service

    # Enable and start the service.
    sudo systemctl enable kloak.service
    sudo systemctl start kloak.service
fi

# Set the desired umask value.
UMASK_VALUE="077"

# Define the files that could define the umask value.
UMASK_FILES=("/etc/profile" "/etc/bash.bashrc" "/etc/login.defs")

# Iterate over the files.
for file in ${UMASK_FILES[@]}; do

    # Check if the file exists.
    if [ -f "$file" ]; then

        echo -e "\n${BOLD_CYAN}Updating UMASK in file $file...${NO_COLOR}"

        # If the file contains an umask setting, change it, if not, add it.
        if grep -q "^umask" $file; then
            sudo sed -i "s/^umask.*/umask $UMASK_VALUE/" $file
        elif [ "$file" != "/etc/login.defs" ]; then
            echo "umask $UMASK_VALUE" | sudo tee -a $file >/dev/null
        fi

        # If the file is /etc/login.defs, handle it separately.
        if [ "$file" == "/etc/login.defs" ]; then
            if grep -q "^UMASK" $file; then
                sudo sed -i "s/^UMASK.*/UMASK $UMASK_VALUE/" $file
            else
                echo "UMASK $UMASK_VALUE" | sudo tee -a $file >/dev/null
            fi
        fi
    fi
done

# TODO: Implement Encrypted Swap.
if ! zramctl >/dev/null; then
    # Installing encrypted swap.
    echo -e "\n${BOLD_CYAN}Installing encrypted swap...${NO_COLOR}"
    sudo paru -S --noconfirm --needed zram-tools

    # Calculate ZRAM size
    ram_gb=$(free -g --si | awk '/Mem:/ { print $2 }')
    if [ "$ram_gb" -le 8 ]; then
        zram_size="$((ram_gb * 95 / 100))G"
    else
        zram_size="8G"
    fi

    echo "Detected RAM: $(free -h --si | awk '/Mem:/ { print $2 }')"
    echo "Configuring ZRAM with size: $zram_size..."

    echo "zram0 /swap zram rw,nosuid,nodev,relatime -o compression=lz4,disksize=$zram_size" | sudo tee /etc/fstab.d/swap
    sudo systemctl enable --now systemd-zram-setup@zram0
fi

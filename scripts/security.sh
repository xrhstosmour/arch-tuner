#!/bin/bash
# ? We are not going to use hardened kernel because we are going to face problems with:
# ? lots of drivers, programming languages, virtualization, processes and many more.
# ? Also the perfomance and usabillity are going to be affected negatively.
# ? So we are going to stick with the default stable kernel and harden manually.

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

# Check if UFW service is active and if not start it.
if ! systemctl is-active --quiet ufw; then
    sudo systemctl start ufw
fi

# Check if UFW service is enabled and if not enable it.
if ! systemctl is-enabled --quiet ufw; then
    sudo systemctl enable ufw
fi

# Check if default deny rules are set and if not set them.
if ! sudo ufw status verbose | grep -q 'Default: deny (incoming), deny (outgoing), deny (routed)'; then
    sudo ufw default deny incoming
    sudo ufw default deny outgoing
    firewall_changes_made=1
fi

# Check if DHCPv6 client rule exists and if not add it.
if ! sudo ufw status | grep -q '546/udp (v6)'; then
    sudo ufw allow out to any port 546 proto udp
    firewall_changes_made=1
fi

# Check if ipv6-icmp rule exists and if not add it.
if ! grep -q 'ufw6-before-output -p ipv6-icmp -j ACCEPT' /etc/ufw/before6.rules; then

    # Add the rule before the COMMIT line.
    sudo sed -i '/COMMIT/ i # Allow outbound ipv6-icmp.\n-A ufw6-before-output -p ipv6-icmp -j ACCEPT' /etc/ufw/before6.rules
    firewall_changes_made=1
fi

# Check if HTTP and HTTPS rules exist and if not add them.
if ! sudo ufw status | grep -q '80/tcp'; then
    sudo ufw allow out to any port 80 proto tcp
    firewall_changes_made=1
fi
if ! sudo ufw status | grep -q '443/tcp'; then
    sudo ufw allow out to any port 443 proto tcp
    firewall_changes_made=1
fi

# Check if DNS rule exists and if not add it.
if ! sudo ufw status | grep -q '53/tcp'; then
    sudo ufw allow out to any port 53 proto tcp
    firewall_changes_made=1
fi
if ! sudo ufw status | grep -q '53/udp'; then
    sudo ufw allow out to any port 53 proto udp
    firewall_changes_made=1
fi

# Check if DHCP client rule exists and if not add it.
if ! sudo ufw status | grep -q '67/udp'; then
    sudo ufw allow out to any port 67 proto udp
    firewall_changes_made=1
fi
if ! sudo ufw status | grep -q '68/udp'; then
    sudo ufw allow out to any port 68 proto udp
    firewall_changes_made=1
fi

# Enabling firewall.
if [ $firewall_changes_made -eq 1 ]; then
    echo -e "\n${BOLD_CYAN}Configuring firewall...${NO_COLOR}"
    echo -e "\n${BOLD_CYAN}Enabling firewall...${NO_COLOR}"
    echo "y" | sudo ufw --force enable
    sudo ufw reload
fi

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

# Get the CPU manufacturer.
cpu_manufacturer=$(grep -m 1 -oP 'vendor_id\s*:\s*\K.*' /proc/cpuinfo)

# Initialize a flag indicating if a microcode update was installed.
microcode_update_installed=false

# Install the appropriate microcode based on the CPU manufacturer.
if [[ $cpu_manufacturer == *'GenuineIntel'* ]]; then
    echo -e "\n${BOLD_CYAN}Installing Intel microcode updates...${NO_COLOR}"
    sudo pacman -S --noconfirm --needed intel-ucode
    microcode_update_installed=true
elif [[ $cpu_manufacturer == *'AuthenticAMD'* ]]; then
    echo -e "\n${BOLD_CYAN}Installing AMD microcode updates...${NO_COLOR}"
    sudo pacman -S --noconfirm --needed amd-ucode
    microcode_update_installed=true
fi

# Update grub to apply microcode updates at boot, only if an update was installed.
if $microcode_update_installed; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# Check if the 'LD_PRELOAD' line already exists in the '/etc/environment' file.
if ! grep -q '^LD_PRELOAD=/usr/lib/libhardened_malloc.so' /etc/environment; then

    # Installing hardened memory allocator.
    echo -e "\n${BOLD_CYAN}Installing hardened memory allocator...${NO_COLOR}"
    paru -S --noconfirm --needed hardened_malloc

    # Enabling hardened memory allocator.
    echo -e "\n${BOLD_CYAN}Enabling hardened memory allocator...${NO_COLOR}"

    # ! Check if this will not create any issues with running applications.
    # If it doesn't exist, add 'LD_PRELOAD=/usr/lib/libhardened_malloc.so' to the end of the file.
    echo 'LD_PRELOAD=/usr/lib/libhardened_malloc.so' | sudo tee -a /etc/environment >/dev/null
fi

# Initialize a variable to track whether a change was made.
dnssec_change_made=false

# Check if the 'DNSSEC' line already exists in the 'resolved.conf' file.
if grep -q '^DNSSEC=' /etc/systemd/resolved.conf; then

    # Check if 'DNSSEC' is set to 'yes'
    if ! grep -q '^DNSSEC=yes' /etc/systemd/resolved.conf; then

        # If it isn't, replace it with 'DNSSEC=yes'
        sudo sed -i 's/^DNSSEC=.*/DNSSEC=yes/' /etc/systemd/resolved.conf
        dnssec_change_made=true
    fi
else

    # If the 'DNSSEC' line doesn't exist, add 'DNSSEC=yes' to the end of the file
    echo 'DNSSEC=yes' | sudo tee -a /etc/systemd/resolved.conf >/dev/null
    dnssec_change_made=true
fi

# If a change was made, restart the 'systemd-resolved' service to apply the changes
if $dnssec_change_made; then

    echo -e "\n${BOLD_CYAN}Enabling DNSSEC...${NO_COLOR}"
    sudo systemctl restart systemd-resolved
fi

# Function to add options to a mount point.
add_mount_options() {
    local mount_point="$1"
    local options="$2"

    # Check if the options are already present.
    if ! grep -q " $mount_point .*defaults,.*$options" /etc/fstab; then

        # If the options are not present, add them.
        if grep -q " $mount_point " /etc/fstab; then
            echo -e "\n${BOLD_CYAN}Adding options $options to mount point $mount_point...${NO_COLOR}"
            sudo sed -i "s|\($mount_point .*\) defaults |\1 defaults,$options |" /etc/fstab
            mountpoint_change_made=1
        fi
    fi
}

# A flag to check if any change is made
mountpoint_change_made=0

# Add nodev, noexec, and nosuid options to /boot and /boot/efi.
add_mount_options "/boot" "nodev,nosuid,noexec"
add_mount_options "/boot/efi" "nodev,nosuid,noexec"

# Add nodev and nosuid options to /home and /root.
add_mount_options "/home" "nodev,nosuid"
add_mount_options "/root" "nodev,nosuid"

# Add nodev, noexec, and nosuid options to directories under /var excluding /var/tmp.
for dir in /var/*; do
    if [[ $dir != "/var/tmp" ]]; then
        add_mount_options "$dir" "nodev,nosuid,noexec"
    fi
done

# Remount all filesystems with new options if any change is made.
if [ $mountpoint_change_made -eq 1 ]; then
    echo -e "\n${BOLD_CYAN}Enabling mountpoint hardening...${NO_COLOR}"
    sudo mount -a
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

# Installing USB port protection.
echo -e "\n${BOLD_CYAN}Installing USB port protection...${NO_COLOR}"
paru -S --noconfirm --needed usbguard

# Configuring USB port protection.
echo -e "\n${BOLD_CYAN}Configuring USB port protection...${NO_COLOR}"
sudo systemctl enable --now usbguard

# Generate an initial policy and allow the already connected devices.
# ? We will use the default police which allows only the already connected devices.
# ? In case you want to allow permanently a device:
# ? 1. Connect the device.
# ? 2. Run 'sudo usbguard list-devices'.
# ? 3. Find the DEVICE_ID of the device you want to allow.
# ? 4. Run 'sudo usbguard generate-policy --device DEVICE_ID | sudo tee -a /etc/usbguard/rules.conf > /dev/null'.
sudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf >/dev/null
sudo chmod 0600 /etc/usbguard/rules.conf
sudo chown root:root /etc/usbguard/rules.conf

# Restart the usbguard service to apply the changes.
sudo systemctl restart usbguard

# Installing encrypted network time security.
echo -e "\n${BOLD_CYAN}Installing encrypted network time security...${NO_COLOR}"
paru -S --noconfirm --needed chrony

# Configuring encrypted network time security.
echo -e "\n${BOLD_CYAN}Configuring encrypted network time security...${NO_COLOR}"
sudo mkdir -p /etc/chrony/ && sudo cp -f ./configurations/network/time.conf /etc/chrony/chrony.conf
sudo chmod 644 /etc/chrony/chrony.conf
sudo chown root:root /etc/chrony/chrony.conf

# Add the seccomp filter option to the environment file.
sudo mkdir -p /etc/sysconfig && echo 'OPTIONS="-F 1"' | sudo tee /etc/sysconfig/chronyd >/dev/null

# Restart the network time security to apply the changes.
systemctl restart chronyd

# Check if Linux kernel runtime guard is installed.
if ! paru -Qq | grep -q '^lkrg-dkms-git$'; then

    # Installing Linux kernel runtime guard.
    echo -e "\n${BOLD_CYAN}Installing Linux kernel runtime guard...${NO_COLOR}"
    paru -S --noconfirm lkrg-dkms-git
fi

# Configure the Linux kernel runtime guard.
echo -e "\n${BOLD_CYAN}Configuring Linux kernel runtime guard...${NO_COLOR}"

# Load the LKRG module into the kernel.
sudo modprobe lkrg

# Ensure LKRG starts at every boot.
# Add 'lkrg' to the MODULES line in /etc/mkinitcpio.conf if it's not already present.
if ! grep -q "^MODULES=.*lkrg" /etc/mkinitcpio.conf; then
    sudo sed -i '/^MODULES=/ s/)/ lkrg)/' /etc/mkinitcpio.conf
fi

# Regenerate the initramfs.
sudo mkinitcpio -P

# Disabling SUID
echo -e "\n${BOLD_CYAN}Disabling SUID...${NO_COLOR}"
sudo find / -perm /4000 -type f -exec chmod u-s {} \;

# TODO: Implement Encrypted Swap.
# TODO: Implement Secure Boot process.
# TODO: Implement Pluggable Authentication Modules (PAM) and U2F/FIDO2 authenticator choice.
# TODO: Implement Mandatory Access Control via AppArmor and its policies/profiles.

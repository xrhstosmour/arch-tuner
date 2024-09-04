#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
SYSTEM_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import log functions and flags.
source "$SYSTEM_SCRIPT_DIRECTORY/logs.sh"
source "$SYSTEM_SCRIPT_DIRECTORY/strings.sh"
source "$SYSTEM_SCRIPT_DIRECTORY/../../core/flags.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

# Function to update system.
# Usage:
#   update_system
update_system() {

    # Constant variable for the world wide mirror.
    local WORLDWIDE_MIRROR='https://geo.mirror.pkgbuild.com/$repo/os/$arch'

    # Check if AUR package manager is installed or not.
    local use_aur_manager=1
    if [[ -n "${AUR_PACKAGE_MANAGER// /}" ]] && command -v "$AUR_PACKAGE_MANAGER" >/dev/null; then
        use_aur_manager=0
    fi

    # Reset mirrors to the worldwide one before updating/upgrading.
    if [[ "$INITIAL_SETUP" -eq 0 ]]; then
        log_info "Resetting mirrors to the worldwide one before updating/upgrading..."
        echo 'Server = '"$WORLDWIDE_MIRROR" | sudo tee /etc/pacman.d/mirrorlist >/dev/null
    fi

    # Upgrade package database format if needed.
    sudo pacman-db-upgrade

    # Update package databases.
    if [[ "$use_aur_manager" -eq 0 ]]; then
        $AUR_PACKAGE_MANAGER -Sy
    else
        sudo $ARCH_PACKAGE_MANAGER -Sy
    fi

    # Check if any package is upgradable.
    upgradable_packages=""
    if [[ "$use_aur_manager" -eq 0 ]]; then
        upgradable_packages=$($AUR_PACKAGE_MANAGER -Qu) || true
    else
        upgradable_packages=$(sudo $ARCH_PACKAGE_MANAGER -Qu) || true
    fi

    # Check if 'archlinux-keyring' package is upgradable.
    upgradable_keyring=$(echo "$upgradable_packages" | grep archlinux-keyring) || true

    # Update 'archlinux-keyring' package if it needs an update.
    if [[ -n "$upgradable_keyring" ]]; then
        log_info "Updating archlinux-keyring..."
        sudo $ARCH_PACKAGE_MANAGER -S --noconfirm --needed archlinux-keyring
    fi

    # Update system if any package is upgradable.
    if [[ -n "$upgradable_packages" ]]; then
        log_info "Updating system..."

        # Update using the corresponding package manager.
        if [[ "$use_aur_manager" -eq 0 ]]; then
            $AUR_PACKAGE_MANAGER -Su --noconfirm
        else
            sudo $ARCH_PACKAGE_MANAGER -Su --noconfirm --needed
        fi
    fi

    # Check if any orphaned packages are available to remove.
    orphan_packages=$(sudo $ARCH_PACKAGE_MANAGER -Qtdq) || true
    if [[ -n "$orphan_packages" ]]; then
        log_info "Removing orphaned packages..."
        sudo $ARCH_PACKAGE_MANAGER -Rns $orphan_packages --noconfirm
    fi

    # Clean up the package and directory cache.
    log_info "Cleaning up package and directory cache..."
    sudo $ARCH_PACKAGE_MANAGER -Scc --noconfirm
    sudo rm -rf ~/.cache/*
}

# Function to stop a process.
# Usage:
#   stop_process "process_name" "message"
stop_process() {
    local process_name="$1"
    local message="${2:-"Stopping $process_name process..."}"

    # Find the process IDs of the process name.
    local process_ids=$(ps aux | grep "$process_name" | grep -v 'grep' | awk '{print $2}')

    # Check if any process IDs were found.
    if [ -n "$process_ids" ]; then
        log_info "$message"

        # Loop through each PID and try to gracefully kill it.
        for process_id in $process_ids; do
            kill "$process_id"
            sleep 1 # Give it a second to terminate
        done

        # Check if any PIDs still exist, then forcefully kill them.
        remaining_process_ids=$(ps aux | grep "$process_name" | grep -v 'grep' | awk '{print $2}')
        if [ -n "$remaining_process_ids" ]; then
            for remaining_process_id in $remaining_process_ids; do
                kill -9 "$remaining_process_id"
            done
        fi
    fi
}

# Function to check if a process is running by its name.
# Usage:
#   is_process_running "process_name"
is_process_running() {
    local process_name="$1"

    # Find the process IDs of the process name.
    local process_ids=$(ps aux | grep "$process_name" | grep -v 'grep' | awk '{print $2}')

    # Check if any process IDs were found.
    if [ -n "$process_ids" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to reboot system if needed.
# Usage:
#   reboot_system "flag" "flag_name" "0_or_1_to_log_warning"
reboot_system() {
    local flag="$1"
    local flag_name="$2"

    # Defaults to 0 (true) to log the warning.
    local log_rerun_warning="${3:-0}"

    # Constant variable for the flags script path.
    local flags_path="$SYSTEM_SCRIPT_DIRECTORY/../../core/flags.sh"

    # Check the value is not equal to 0 (true) and reboot.
    if [ "$flag" -ne 0 ]; then
        log_error "System requires a reboot to apply changes!"
        if [ "$log_rerun_warning" -eq 0 ]; then
            log_warning -n "After the system restarts, please rerun the entire script!"
        fi
        log_info -n "Initiating system reboot..."
        sleep 10

        # Change the value of the flag to 0 (true), before rebooting.
        change_flag_value "$flag_name" 0 "$flags_path"

        # Reboot the system immediately.
        exec sudo reboot
    fi
}

# Function to remove all installed packages, returning the system to a clean Arch Linux installation state.
# Usage:
#   reset_system_to_clean_state
reset_system_to_clean_state() {

    # Constant variable for the flags script path.
    local flags_path="$SYSTEM_SCRIPT_DIRECTORY/../../core/flags.sh"

    # URL of a fresh Arch Linux installation package list.
    PACKAGE_LIST_URL="https://geo.mirror.pkgbuild.com/iso/latest/arch/pkglist.x86_64.txt"

    # Create a temporary file to store the package list.
    TEMPORARY_PACKAGE_LIST=$(mktemp)

    # Download the package list.
    if ! curl -s $PACKAGE_LIST_URL -o $TEMPORARY_PACKAGE_LIST; then
        log_error "Failed to download the fresh Arch Linux installation package list!"
        return 1
    fi

    # Extract package names from the list.
    FRESH_INSTALLTION_PACKAGES=$(awk '{print $1}' $TEMPORARY_PACKAGE_LIST)

    # Remove all AUR packages.
    log_info "Removing all AUR packages..."
    AUR_PACKAGES=$(sudo $ARCH_PACKAGE_MANAGER -Qqm) || true
    if [ -n "$AUR_PACKAGES" ]; then
        echo "$AUR_PACKAGES" | xargs sudo $ARCH_PACKAGE_MANAGER -Rdd --noconfirm --
    fi

    # Mark all installed packages as dependencies.
    log_info "Marking all installed packages as dependencies..."
    sudo $ARCH_PACKAGE_MANAGER -D --asdeps $($ARCH_PACKAGE_MANAGER -Qqe)

    # Define essential packages.
    declare -a ESSENTIAL_PACKAGES=(
        base
        linux
        linux-firmware
        grub
        efibootmgr
        os-prober
        microcode
        db
        amd-ucode
        intel-ucode
        e2fsprogs
        xfsprogs
        btrfs-progs
        lvm2
        mdadm
        sof-firmware
        linux-firmware-marvell
        broadcom-wl
        networkmanager
        dhclient
        wpa_supplicant
        modemmanager
        man-db
        man-pages
        dosfstools
        udftools
        reiserfsprogs
        ntfs-3g
        nilfs-utils
        jfsutils
        hfsprogs
        f2fs-tools
        exfatprogs
        zfs-utils
        dhcpcd
        connman
        netctl
        systemd
        iwd
    )

    # Mark essential packages as explicitly installed.
    log_info "Excluding essential packages from removal..."
    for package in "${ESSENTIAL_PACKAGES[@]}"; do
        if pacman -Q $package &> /dev/null; then
            sudo $ARCH_PACKAGE_MANAGER -D --asexplicit $package
        fi
    done

    log_info "Excluding fresh installation packages from removal..."
    for package in $FRESH_INSTALLTION_PACKAGES; do
        if pacman -Q $package &> /dev/null; then
            sudo $ARCH_PACKAGE_MANAGER -D --asexplicit $package
        fi
    done

    # Remove all unused/orphan packages.
    log_info "Removing all unnecessary packages..."
    UNNECESSARY_PACKAGES=$(sudo $ARCH_PACKAGE_MANAGER -Qdtq) || true
    if [ -n "$UNNECESSARY_PACKAGES" ]; then
        echo "$UNNECESSARY_PACKAGES" | xargs sudo $ARCH_PACKAGE_MANAGER -Rns --noconfirm -- 2>/dev/null
    fi

    # Delete the temporary package list file.
    rm $TEMPORARY_PACKAGE_LIST

    # Change the default shell to Bash.
    log_info "Changing the default shell to Bash..."
    sudo chsh -s /bin/bash $USER

    log_info "System reset to a clean Arch Linux installation state!"

    # Change the value of the flag to 0 (true) after resetting the system and reboot.
    reboot_system $SYSTEM_RESET "SYSTEM_RESET"
}

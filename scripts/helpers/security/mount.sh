#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
MOUNT_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$MOUNT_SCRIPT_DIRECTORY/../functions.sh"

# Initialize a flag indicating if a mount options change has been made.
mount_changes_made=1

# Mount constant configuration variables.
MOUNT_NO_DEV_OPTION="nodev"
MOUNT_NO_SUID_OPTION="nosuid"
MOUNT_NO_EXEC_OPTION="noexec"

# To each function execution proceed to change the && mount_changes_made flag to 0 (true), only if the mount point option changed (function returned 0 (true)).
# Add nodev, noexec, and nosuid options to /boot and /boot/efi.
add_mount_options "/boot" "$MOUNT_NO_DEV_OPTION,$MOUNT_NO_SUID_OPTION,$MOUNT_NO_EXEC_OPTION" && mount_changes_made=0
add_mount_options "/boot/efi" "$MOUNT_NO_DEV_OPTION,$MOUNT_NO_SUID_OPTION,$MOUNT_NO_EXEC_OPTION" && mount_changes_made=0

# Add nodev and nosuid options to /home and /root.
add_mount_options "/home" "$MOUNT_NO_DEV_OPTION,$MOUNT_NO_SUID_OPTION" && mount_changes_made=0
add_mount_options "/root" "$MOUNT_NO_DEV_OPTION,$MOUNT_NO_SUID_OPTION" && mount_changes_made=0

# Add nodev, noexec, and nosuid options to directories under /var excluding /var/tmp.
for dir in /var/*; do
    if [[ $dir != "/var/tmp" ]]; then
        add_mount_options "$dir" "$MOUNT_NO_DEV_OPTION,$MOUNT_NO_SUID_OPTION,$MOUNT_NO_EXEC_OPTION" && mount_changes_made=0
    fi
done

# Remount all filesystems with new options if any change is made.
if [ $mount_changes_made -eq 0 ]; then
    log_info "Enabling mount point hardening..."
    sudo mount -a
fi

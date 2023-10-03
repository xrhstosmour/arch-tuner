#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
MOUNT_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$MOUNT_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Initialize a flag indicating if a mount options change has been made.
mount_options_changes_made=1

# Declare constant variables for mounting options.
MOUNT_DEFAULTS_OPTION="defaults"
MOUNT_NO_DEV_OPTION="nodev"
MOUNT_NO_SUID_OPTION="nosuid"
MOUNT_NO_EXEC_OPTION="noexec"

# Define mount points and their associated options
declare -A mount_options
mount_options=(
    ["/"]="$MOUNT_DEFAULTS_OPTION"
    ["/home"]="$MOUNT_DEFAULTS_OPTION,$MOUNT_NO_SUID_OPTION,$MOUNT_NO_EXEC_OPTION,$MOUNT_NO_DEV_OPTION"
    ["/boot"]="$MOUNT_DEFAULTS_OPTION,$MOUNT_NO_SUID_OPTION,$MOUNT_NO_EXEC_OPTION,$MOUNT_NO_DEV_OPTION"
)

# Seperate /var subfolders and /var/tmp constant variables.
VAR_SUBFOLDERS_DIRECTORY="/var/*"
VAR_TMP_DIRECTORY="/var/tmp"

# Iterate through each mount point and apply the associated options accordingly.
for mount_point in "${!mount_options[@]}"; do
    mount_options_changed=$(update_mount_options "$mount_point" "${mount_options[$mount_point]}")
    if [ "$mount_options_changed" = "true" ]; then
        mount_options_changes_made=0
    fi
done

# Handle the /var subfolders separately due to the exclusion of /var/tmp.
# Add defaults and nosuid options to directories under /var excluding /var/tmp.
for dir in $VAR_SUBFOLDERS_DIRECTORY; do
    if [[ $dir != "$VAR_TMP_DIRECTORY" ]]; then
        mount_options_changed=$(update_mount_options "$dir" "$MOUNT_DEFAULTS_OPTION,$MOUNT_NO_SUID_OPTION")
        if [ "$mount_options_changed" = "true" ]; then
            mount_options_changed=0
        fi
    fi
done

# Remount all filesystems with new options if any change is made.
if [ $mount_options_changes_made -eq 0 ]; then
    log_info "Enabling mount point hardening..."
    sudo mount -a
fi

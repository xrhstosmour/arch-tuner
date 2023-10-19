#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
IDS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$IDS_SCRIPT_DIRECTORY/../functions/logs.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# UID constant configuration variables.
SBIN_DIRECTORY="/sbin"
USR_DIRECTORY="/usr"
BIN_DIRECTORY="/bin"
OPT_DIRECTORY="/opt"
ROOT_DIRECTORY="/root"
BOOT_DIRECTORY="/boot"
SUID_PERMISSION="4000"
SGID_PERMISSION="2000"

# Construct the exclusion pattern using the directories.
EXCLUDE_DIRS="^$SBIN_DIRECTORY/.*|^$USR_DIRECTORY/.*|^$BIN_DIRECTORY/.*|^$OPT_DIRECTORY/.*|^$ROOT_DIRECTORY/.*|^$BOOT_DIRECTORY/.*"

# Find all binaries with setuid or setgid bits set, excluding the directories listed above.
suid_sgid_files=$(sudo find / -type f \( \( -perm -$SUID_PERMISSION -o -perm -$SGID_PERMISSION \) ! -regex "$EXCLUDE_DIRS" \) 2>/dev/null)

# If any such files are found, disable their setuid and setgid bits.
if [[ ! -z "$suid_sgid_files" ]]; then
    log_info "Disabling Set owner User ID (SUID) and Set Group ID (SGID) on these files..."
    sudo chmod u-s,g-s $suid_sgid_files
fi

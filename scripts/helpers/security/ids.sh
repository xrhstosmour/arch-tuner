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

# SUID constant configuration variables.
SBIN_DIRECTORY="/sbin"
USR_DIRECTORY="/usr"
BIN_DIRECTORY="/bin"
OPT_DIRECTORY="/opt"
ROOT_DIRECTORY="/root"
BOOT_DIRECTORY="/boot"
SUID_PERMISSION="4000"
SGID_PERMISSION="2000"

# Find command to locate all files with SUID and SGID enabled outside the specified directories.
FIND_SUID_AND_SGID_COMMAND="sudo find / -path /proc -prune -o -path /sys -prune -o \( -path \"$SBIN_DIRECTORY\" -o -path \"$USR_DIRECTORY\" -o -path \"$BIN_DIRECTORY\" -o -path \"$OPT_DIRECTORY\" -o -path \"$ROOT_DIRECTORY\" -o -path \"$BOOT_DIRECTORY\" \) -prune -o \( -perm /$SUID_PERMISSION -o -perm /$SGID_PERMISSION \) -type f -print"

# Check if any file has SUID enabled outside the specified directories.
if eval "$FIND_SUID_AND_SGID_COMMAND" | grep -q .; then
    log_info "Disabling Set owner User ID (SUID) and Set Group ID (SGID)..."
    eval "$FIND_SUID_AND_SGID_COMMAND -exec chmod u-s,g-s {} \;"
fi

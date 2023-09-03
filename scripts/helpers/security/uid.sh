#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
UID_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$UID_SCRIPT_DIRECTORY/../functions.sh"

# SUID constant configuration variables.
SBIN_DIRECTORY="/sbin"
USR_DIRECTORY="/usr"
BIN_DIRECTORY="/bin"
OPT_DIRECTORY="/opt"
ROOT_DIRECTORY="/root"
BOOT_DIRECTORY="/boot"

# Find command to locate all files with SUID enabled outside the specified directories
FIND_SUID_COMMAND="sudo find / \( -path \"$SBIN_DIRECTORY\" -o -path \"$USR_DIRECTORY\" -o -path \"$BIN_DIRECTORY\" -o -path \"$OPT_DIRECTORY\" -o -path \"$ROOT_DIRECTORY\" -o -path \"$BOOT_DIRECTORY\" \) -prune -o -perm /4000 -type f -print"

# Check if any file has SUID enabled outside the specified directories.
if eval "$FIND_SUID_CMD" | grep -q .; then
    log_info "Disabling Set owner User ID (SUID)..."
    eval "$FIND_SUID_CMD -exec chmod u-s {} \;"
fi

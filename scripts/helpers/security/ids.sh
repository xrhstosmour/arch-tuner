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
declare -a EXCLUDE_PATHS=(
    "/sys"
    "/proc"
    "/sbin"
    "/usr"
    "/bin"
    "/opt"
    "/root"
    "/boot"
    "/usr/bin/sudo"
    "/usr/bin/su"
    "/usr/bin/passwd"
    "/usr/bin/gpasswd"
    "/usr/bin/newgrp"
    "/usr/bin/chsh"
    "/usr/bin/chfn"
    "/usr/libexec/openssh/ssh-keysign"
    "/usr/bin/crontab"
    "/usr/bin/at"
    "/usr/bin/screen"
    "/usr/sbin/unix_chkpwd"
    "/usr/bin/pkexec"
    "/usr/bin/mtr"
    "/usr/bin/ksu"
)

# Construct the exclude arguments for the find command.
EXCLUDE_ARGUMENTS=""
for path in "${EXCLUDE_PATHS[@]}"; do
    EXCLUDE_ARGUMENTS="$EXCLUDE_ARGUMENTS ! -path $path"
done

# Find all binaries with setuid or setgid bit set, excluding specified paths.
suid_sgid_binary_files=$(sudo find / \( $EXCLUDE_ARGUMENTS \) \( -type f \( -perm -4000 -o -perm -2000 \) \) 2>/dev/null)
if [[ -z "$suid_sgid_binary_files" ]]; then
    log_info "No SUID/SGID binaries found!"
    exit 0
fi

# Iterate to remove the setuid and setgid bits from the files which were found.
for binary_file in $suid_sgid_binary_files; do

    # Check if the binary file has setuid bit set.
    if [[ $(stat -c "%a" "$binary_file") == *4* ]]; then
        log_info "Disabling Set Owner User ID (SUID) from $binary_file..."
        sudo chmod u-s "$binary_file"
    fi

    # Check if the binary file has setgid bit set.
    if [[ $(stat -c "%a" "$binary_file") == *2* ]]; then
        log_info "Disabling Set Group ID (SGID) from $binary_file..."
        sudo chmod g-s "$binary_file"
    fi
done

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
IDS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$IDS_SCRIPT_DIRECTORY/../functions/logs.sh"

# UID constant configuration variables.
declare -a EXCLUDE_PATHS=(
    "/sys"
    "/proc"
    "/sbin"
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

# Start with the basic command.
FIND_COMMAND="sudo find /"

# Then we add each excluded path.
for path in "${EXCLUDE_PATHS[@]}"; do

    # If this is not the last path in EXCLUDE_PATHS add the '-o' otherwise omit it.
    if [[ "$path" != "${EXCLUDE_PATHS[-1]}" ]]; then
        FIND_COMMAND="${FIND_COMMAND} -path $path -prune -o"
    else
        FIND_COMMAND="${FIND_COMMAND} -path $path -prune"
    fi
done

# Finally, we add the part that selects the files of interest.
FIND_COMMAND="${FIND_COMMAND} -o -type f \( -perm -4000 -o -perm -2000 \) -print"

# Execute the final command.
suid_sgid_binary_files=$(eval $FIND_COMMAND 2>&1 | grep -v "File system loop detected" || true)
if [[ -z "$suid_sgid_binary_files" ]]; then
    log_info "No SUID/SGID binaries found!"
    exit 0
fi

# Iterate to remove the setuid and setgid bits from the files which were found.
for binary_file in $suid_sgid_binary_files; do

    # Check if the binary file has setuid bit set.
    if [[ $(stat -c "%a" "$binary_file") == 4* ]]; then
        log_info "Disabling Set Owner User ID (SUID) from $binary_file..."
        sudo chmod u-s "$binary_file"
    fi

    # Check if the binary file has setgid bit set.
    if [[ $(stat -c "%a" "$binary_file") == 2* ]]; then
        log_info "Disabling Set Group ID (SGID) from $binary_file..."
        sudo chmod g-s "$binary_file"
    fi
done

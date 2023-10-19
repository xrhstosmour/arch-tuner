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
declare -a EXCLUDE_DIRS=(
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
SUID_PERMISSION="4000"
SGID_PERMISSION="2000"

directories_to_process=("/")
while ((${#directories_to_process[@]})); do
    current_directory="${directories_to_process[0]}"
    directories_to_process=("${directories_to_process[@]:1}")

    # If the directory is not in the directories to exclude.
    if [[ ! " ${EXCLUDE_DIRS[@]} " =~ " ${current_directory} " ]]; then
        for entry in "$current_directory"/*; do
            if [[ -d "$entry" && ! -L "$entry" ]]; then
                directories_to_process+=("$entry")
            elif [[ -f "$entry" ]]; then

                # Get the permissions
                permissions=$(stat -c %a "$entry")
                if (((permissions & SUID_PERMISSION) == SUID_PERMISSION || (permissions & SGID_PERMISSION) == SGID_PERMISSION)); then
                    log_info "Disabling Set owner User ID (SUID) and Set Group ID (SGID) on $entry..."
                    sudo chmod u-s,g-s "$entry"
                fi
            fi
        done
    fi
done

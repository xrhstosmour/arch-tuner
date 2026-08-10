#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
IDS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$IDS_SCRIPT_DIRECTORY/../functions/logs.sh"

# Initialize a flag to track whether a change was made.
ids_changes_made=1

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
FIND_COMMAND=(sudo find /)

# Then we add each excluded path.
for path in "${EXCLUDE_PATHS[@]}"; do

    # If this is not the last path in EXCLUDE_PATHS add the '-o' otherwise omit it.
    if [[ "$path" != "${EXCLUDE_PATHS[-1]}" ]]; then
        FIND_COMMAND+=(-path "$path" -prune -o)
    else
        FIND_COMMAND+=(-path "$path" -prune)
    fi
done

# Finally, we add the part that selects the files of interest. NUL-separated
# output (-print0) lets paths containing whitespace survive the loop below
# intact instead of being word-split into bogus tokens.
FIND_COMMAND+=(-o -type f "(" -perm -4000 -o -perm -2000 ")" -print0)

# Execute the final command, discarding stderr noise like "File system loop
# detected" from the excluded/pruned paths above.
suid_sgid_binary_files=()
while IFS= read -r -d '' binary_file; do
    suid_sgid_binary_files+=("$binary_file")
done < <("${FIND_COMMAND[@]}" 2>/dev/null)

if [[ ${#suid_sgid_binary_files[@]} -eq 0 ]]; then
    log_info "No SUID/SGID binaries found!"
    exit 0
fi

# Iterate to remove the setuid and setgid bits from the files found.
for binary_file in "${suid_sgid_binary_files[@]}"; do

    # Check if the file exists and is a regular file before proceeding.
    if [[ -e "$binary_file" && -f "$binary_file" ]]; then

        # Derive the special-bits digit (suid=4, sgid=2, sticky=1) and test
        # each bit independently with bitwise AND, a mode of 6755 (both suid
        # and sgid set) matches neither a "4*" nor a "2*" prefix check.
        file_mode=$(stat -c "%a" "$binary_file" 2>/dev/null)
        special_bits=$(printf '%04o' "0$file_mode")
        special_bits=${special_bits:0:1}

        # Check if the binary file has setuid bit set.
        if (( special_bits & 4 )); then
            log_info "Disabling Set Owner User ID (SUID) from $binary_file..."
            sudo chmod u-s "$binary_file"
        fi

        # Check if the binary file has setgid bit set.
        if (( special_bits & 2 )); then
            log_info "Disabling Set Group ID (SGID) from $binary_file..."
            sudo chmod g-s "$binary_file"
        fi
    fi
done

# Deploy the pacman hook to automatically strip SUID/SGID after updates.
HOOK_DIRECTORY="$IDS_SCRIPT_DIRECTORY/../../configurations/security/ids"
HOOK_SOURCE="$HOOK_DIRECTORY/99-strip-suid-sgid.hook"
HOOK_TARGET="/etc/pacman.d/hooks/99-strip-suid-sgid.hook"

# Ensure the target hook directory exists.
if [ ! -d "/etc/pacman.d/hooks" ]; then
    sudo mkdir -p "/etc/pacman.d/hooks"
fi

# Copy the hook file if different from the target.
sudo cp "$HOOK_SOURCE" "$HOOK_TARGET"
are_files_the_same=$(compare_files "$HOOK_TARGET" "$HOOK_SOURCE")
if [ "$are_files_the_same" = "false" ]; then
    ids_changes_made=0
fi

# If a change was made, reload systemd to ensure the hook is loaded.
if [ $ids_changes_made -eq 0 ]; then
    log_info "Deploying SUID/SGID stripping pacman hook."
    # Note: pacman hooks are loaded automatically at runtime, no need for daemon-reload
fi

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SWAP_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SWAP_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$SWAP_SCRIPT_DIRECTORY/../functions/logs.sh"

# Constant variables for the encrypted swap file. Adjust the size for the
# host's actual RAM, 2 GiB is a reasonable default for a general-purpose VPS.
SWAP_FILE="/swapfile"
SWAP_FILE_SIZE_MEBIBYTES="2048"
CRYPTTAB="/etc/crypttab"

# The "swap" option tells systemd to format this mapping with mkswap and
# activate it on every boot automatically, using a fresh random key from
# /dev/urandom each time instead of a persisted one. Swap contents can never
# outlive a reboot this way, so there is no key to manage or leak.
CRYPTTAB_ENTRY="swap $SWAP_FILE /dev/urandom swap,cipher=aes-xts-plain64,size=256"

# Install disk encryption tooling, systemd links against libcryptsetup to
# process crypttab, but it is only an optional dependency of the systemd
# package, not installed by default.
install_packages "cryptsetup" "$ARCH_PACKAGE_MANAGER" "Installing disk encryption tooling..."

# Create the swap backing file if it does not exist yet.
if [ ! -f "$SWAP_FILE" ]; then
    log_info "Creating $SWAP_FILE_SIZE_MEBIBYTES MiB swap file..."
    sudo touch "$SWAP_FILE"
    sudo chmod 600 "$SWAP_FILE"
    sudo dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$SWAP_FILE_SIZE_MEBIBYTES" status=none
fi

# Add the crypttab entry that maps the swap file through a random key on
# every boot. This takes effect on the next reboot, matching every other
# kernel-level change this toolkit applies.
if ! grep -qxF "$CRYPTTAB_ENTRY" "$CRYPTTAB" 2>/dev/null; then
    log_info "Adding encrypted swap mapping to $CRYPTTAB..."
    echo "$CRYPTTAB_ENTRY" | sudo tee -a "$CRYPTTAB" >/dev/null
else
    log_info "Encrypted swap mapping already configured."
fi

#!/bin/bash

set -e

MIRRORLIST="/etc/pacman.d/mirrorlist"
MIRRORLIST_BACKUP="/etc/pacman.d/mirrorlist.bak"
MIRRORS_FILE="mirrors.txt"

rate-mirrors --disable-comments-in-file --save "$MIRRORS_FILE" arch

# Reject an empty or unusable result instead of overwriting a working
# mirrorlist with junk from a transient network blip during probing, that
# would break every subsequent pacman/AUR call in the same run.
if ! grep -q '^Server = ' "$MIRRORS_FILE"; then
    echo "rate-mirrors produced no usable servers, keeping the existing mirrorlist." >&2
    rm -f "$MIRRORS_FILE"
    exit 1
fi

sudo cp -f "$MIRRORLIST" "$MIRRORLIST_BACKUP"
head -n 5 "$MIRRORS_FILE" | sudo tee "$MIRRORLIST" >/dev/null
rm -f "$MIRRORS_FILE"

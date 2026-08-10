#!/bin/bash

# Downloads arch-tuner into a fresh temporary directory and runs the
# installer, for a quick install without a manual git clone first. Review
# this file before piping it into a shell, it fetches and executes the rest
# of the repository afterward.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/xrhstosmour/arch-tuner/main/bootstrap.sh | sudo bash

set -e

REPOSITORY_URL="https://github.com/xrhstosmour/arch-tuner.git"
CLONE_DIRECTORY=$(mktemp -d)

cleanup() {
    rm -rf "$CLONE_DIRECTORY"
}
trap cleanup EXIT

if ! command -v git &>/dev/null; then
    # -Sy alone (sync without upgrade) is the classic Arch "partial upgrade"
    # anti-pattern; -Syu keeps the sync and install in one consistent
    # transaction with the rest of the system.
    pacman -Syu --noconfirm --needed git
fi

git clone --depth 1 "$REPOSITORY_URL" "$CLONE_DIRECTORY"
cd "$CLONE_DIRECTORY"

# Reopen the controlling terminal for install.sh's prompts, this script's own
# stdin is the curl|bash pipe, already exhausted by the time it gets here.
./install.sh </dev/tty

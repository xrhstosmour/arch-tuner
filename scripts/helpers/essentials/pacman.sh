#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
PACMAN_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PACMAN_SCRIPT_DIRECTORY/../functions/packages.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variables for configuring the Arch package manager.
PACMAN_CONFIGURATION="/etc/pacman.conf"

# Configure Arch package manager.
if ! grep -q '^Color' "$PACMAN_CONFIGURATION" || ! grep -q '^ParallelDownloads' "$PACMAN_CONFIGURATION"; then
    log_info "Configuring $ARCH_PACKAGE_MANAGER package manager..."
fi

# Enable colors in terminal.
if ! grep -q '^Color' $PACMAN_CONFIGURATION; then
    log_info "Enabling colors in terminal..."
    sudo sed -i '/^#.*Color/s/^#//' $PACMAN_CONFIGURATION
fi

# Enable parallel downloads.
if ! grep -q '^ParallelDownloads' $PACMAN_CONFIGURATION; then
    log_info "Enabling parallel downloads..."
    sudo sed -i '/^#.*ParallelDownloads/s/^#//' $PACMAN_CONFIGURATION
fi

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
MEMORY_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$MEMORY_SCRIPT_DIRECTORY/../functions/packages.sh"

# Constant variables for keeping the hardened memory allocator configuration.
HARDENED_MEMORY_ALLOCATOR_CONFIGURATION="LD_PRELOAD=/usr/lib/libhardened_malloc.so"
HARDENED_MEMORY_ALLOCATOR_CONFIGURATION_DIRECTORY="/etc/environment"

# Install hardened memory allocator.
install_packages "hardened_malloc" "$AUR_PACKAGE_MANAGER" "Installing hardened memory allocator..."

# Enable hardened memory allocator.
if ! grep -q "^$HARDENED_MEMORY_ALLOCATOR_CONFIGURATION" "$HARDENED_MEMORY_ALLOCATOR_CONFIGURATION_DIRECTORY"; then
    log_info "Enabling hardened memory allocator..."

    # Add 'LD_PRELOAD=/usr/lib/libhardened_malloc.so' to the end of the file.
    echo "$HARDENED_MEMORY_ALLOCATOR_CONFIGURATION" | sudo tee -a "$HARDENED_MEMORY_ALLOCATOR_CONFIGURATION_DIRECTORY" >/dev/null
fi

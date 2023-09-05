#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
VMWARE_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$VMWARE_SCRIPT_DIRECTORY/../../functions.sh"

# Constant variable containing the VMWARE graphics drivers.
VMWARE_DRIVERS="mesa"
OPEN_VM_TOOLS="open-vm-tools xf86-input-vmmouse xf86-video-vmware gtkmm"
XWRAPPER_CONFIGURATION="/etc/X11/Xwrapper.config"
OPEN_VM_TOOLS_CONFIGURATION="needs_root_rights=yes"

# Install VMWARE drivers.
install_packages "$VMWARE_DRIVERS" "$AUR_PACKAGE_MANAGER" "Installing VMWARE drivers..."

# Install Open VM Tools.
install_packages "$OPEN_VM_TOOLS" "$AUR_PACKAGE_MANAGER" "Installing open VM tools..."

# Configure Open VM Tools.
if ! grep -q "$OPEN_VM_TOOLS_CONFIGURATION" "$XWRAPPER_CONFIGURATION"; then
    log_info "Configuring open VM tools..."
    echo "$OPEN_VM_TOOLS_CONFIGURATION" | sudo tee -a "$XWRAPPER_CONFIGURATION" >/dev/null
fi

# Start and enable Open VM Tools service.
start_service "vmtoolsd" "Starting open VM tools service..."
enable_service "vmtoolsd" "Enabling open VM tools service..."

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SECURE_BOOT_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SECURE_BOOT_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$SECURE_BOOT_SCRIPT_DIRECTORY/../functions/logs.sh"

# Secure Boot only applies to a system booted via UEFI.
if [ ! -d /sys/firmware/efi ]; then
    log_info "Not booted via UEFI, Secure Boot does not apply here."
    exit 0
fi

# Install Secure Boot key creation and signing management.
install_packages "sbctl" "$ARCH_PACKAGE_MANAGER" "Installing Secure Boot management..."

# Create this machine's own Secure Boot keys if none exist yet. This only
# writes key material to disk, it does not touch the firmware or any boot
# file, safe to run unattended.
if [ ! -d /usr/share/secureboot/keys ]; then
    log_info "Creating Secure Boot keys..."
    sudo sbctl create-keys
fi

# Enrolling these keys into firmware and signing the bootloader and kernel
# are deliberately left as manual, administrator-reviewed steps. A mistake
# here, a boot file left unsigned, an interrupted enrollment, can leave a
# remote server refusing to boot at all with no console to recover from.
log_warning "Secure Boot keys are ready, but not enrolled or signed."
log_warning "Review 'sudo sbctl status' yourself, then enroll and sign following"
log_warning "sbctl's own current documentation for your installed version."
log_warning "Getting this wrong can leave a remote server unable to boot."

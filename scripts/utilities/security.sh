#!/bin/bash
# ? We are not going to use hardened kernel because we are going to face problems with:
# ? drivers, programming languages, virtualization, processes and many more.
# ? Also the perfomance and usabillity are going to be affected negatively.
# ? So we are going to stick with the default stable kernel and harden manually.

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SECURITY_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SECURITY_SCRIPT_DIRECTORY/../helpers/functions/packages.sh"
source "$SECURITY_SCRIPT_DIRECTORY/../helpers/functions/filesystem.sh"
source "$SECURITY_SCRIPT_DIRECTORY/../helpers/functions/system.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variable for the file path containing the security applications to install.
SECURITY_PACKAGES="$SECURITY_SCRIPT_DIRECTORY/../packages/security.txt"

# Check if at least one security package is not installed.
are_security_packages_installed=$(are_packages_installed "$SECURITY_PACKAGES" "$AUR_PACKAGE_MANAGER")
if [ "$are_security_packages_installed" = "false" ]; then
    log_info "Installing security applications..."

    # Install security packages.
    install_packages "$SECURITY_PACKAGES" "$AUR_PACKAGE_MANAGER"
fi

# Install and configure firewall.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/firewall.sh

# Reboot system if needed and do not log the rerun warning.
reboot_system "$REBOOTED_AFTER_FIREWALL" "REBOOTED_AFTER_FIREWALL"

# Install and configure antivirus.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/antivirus.sh

# Install and configure cpu updates.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/cpu.sh

# Install and configure memory allocator.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/memory.sh

# Configure DNS.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/dns.sh

# Install and configure USB port protection.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/usb.sh

# Install and configure encrypted network time security.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/nts.sh

# TODO: Implement Linux kernel runtime guard when there is support for newer kernels.
# TODO: Implement Secure Boot process.
# TODO: Implement Pluggable Authentication Modules (PAM) and U2F/FIDO2 authenticator choice.
# TODO: Implement Mandatory Access Control via AppArmor and its policies/profiles.

# Configure mount options.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/mount.sh

# Configure owner user IDs.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/ids.sh

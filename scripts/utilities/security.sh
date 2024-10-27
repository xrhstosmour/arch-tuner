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

# Import functions and flags.
source "$SECURITY_SCRIPT_DIRECTORY/../helpers/functions/packages.sh"
source "$SECURITY_SCRIPT_DIRECTORY/../helpers/functions/filesystem.sh"
source "$SECURITY_SCRIPT_DIRECTORY/../helpers/functions/system.sh"
source "$SECURITY_SCRIPT_DIRECTORY/../core/flags.sh"

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

# Install and configure firewall.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/firewall.sh

# Configure mount points for extra hardening.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/mount.sh

# Configure owner user IDs.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/ids.sh

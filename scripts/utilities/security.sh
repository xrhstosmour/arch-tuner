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

# Install and configure encrypted network time security.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/nts.sh

# Configure DNS.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/dns.sh

# Install and configure firewall.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/firewall.sh

# Configure owner user IDs.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/ids.sh

# TODO: Implement Linux kernel runtime guard when there is support for newer kernels.
# TODO: Implement Secure Boot process.
# TODO: Implement Pluggable Authentication Modules (PAM) and U2F/FIDO2 authenticator choice.
# TODO: Implement Mandatory Access Control via AppArmor and its policies/profiles.

# Configure mount points for extra hardening.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/mount.sh

# Create administrative user.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/user.sh

# Configure SSH server hardening.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/ssh.sh

# Harden sudoers configuration.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/sudoers.sh

# Install and configure fail2ban.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/fail2ban.sh

# Apply kernel sysctl hardening.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/sysctl.sh

# Harden systemd services.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/systemd.sh

# Configure systemd journald.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/journald.sh

# Configure AIDE integrity monitoring.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/aide.sh

# Configure audit daemon.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/auditd.sh

# Configure automatic system updates.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/automatic-updates.sh

# Harden Docker engine.
sh $SECURITY_SCRIPT_DIRECTORY/../helpers/security/docker-engine.sh

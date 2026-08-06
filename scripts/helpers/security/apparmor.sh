#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
APPARMOR_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$APPARMOR_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$APPARMOR_SCRIPT_DIRECTORY/../functions/services.sh"
source "$APPARMOR_SCRIPT_DIRECTORY/../functions/logs.sh"

# Install AppArmor and its management tools.
install_packages "apparmor apparmor-utils" "$ARCH_PACKAGE_MANAGER" "Installing AppArmor..."

# Enable and start the service that loads profiles at boot, harmless even
# before the kernel parameter below is set, it simply has nothing to load.
enable_service "apparmor.service" "Enabling AppArmor..."
start_service "apparmor.service" "Starting AppArmor..."

# Default any existing profiles to complain mode, logging violations instead
# of enforcing them, so nothing breaks silently before an administrator has
# reviewed the logs with aa-logprof and chosen which profiles to enforce.
mapfile -d '' -t profile_files < <(find /etc/apparmor.d -maxdepth 1 -type f -print0 2>/dev/null)
if [ "${#profile_files[@]}" -gt 0 ]; then
    log_info "Setting existing AppArmor profiles to complain mode..."
    sudo aa-complain "${profile_files[@]}"
else
    log_info "No AppArmor profiles found yet, nothing to set to complain mode."
fi

# Check whether the apparmor LSM is actually active on this boot. Enabling it
# needs a kernel command line change, which this helper deliberately does not
# automate, a bad edit to the bootloader configuration can leave a remote
# server unable to boot with no console to fix it from.
if [ ! -e /sys/module/apparmor/parameters/enabled ] || [ "$(cat /sys/module/apparmor/parameters/enabled)" != "Y" ]; then
    log_warning "AppArmor is installed but not active on this boot."
    log_warning "Add 'apparmor' to the kernel's lsm= parameter and reboot to enable it."
    log_warning "Current active LSMs: $(cat /sys/kernel/security/lsm 2>/dev/null || echo "unknown")."
    log_warning "For GRUB: append it to the lsm= list in /etc/default/grub's GRUB_CMDLINE_LINUX_DEFAULT, then run 'sudo grub-mkconfig -o /boot/grub/grub.cfg'."
fi

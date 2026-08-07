#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
FAIL2BAN_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$FAIL2BAN_SCRIPT_DIRECTORY/../functions/logs.sh"
source "$FAIL2BAN_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$FAIL2BAN_SCRIPT_DIRECTORY/../functions/services.sh"
source "$FAIL2BAN_SCRIPT_DIRECTORY/../functions/filesystem.sh"
source "$FAIL2BAN_SCRIPT_DIRECTORY/../functions/ui.sh"

# Constant variables for the fail2ban configuration paths.
FAIL2BAN_CONFIGURATION="/etc/fail2ban/jail.local"
FAIL2BAN_CONFIGURATION_TO_PASS="$FAIL2BAN_SCRIPT_DIRECTORY/../../configurations/security/fail2ban/jail.local"

# Install the fail2ban package.
install_packages "fail2ban" "$AUR_PACKAGE_MANAGER" "Installing fail2ban..."

# Copy the hardened configuration if it differs from the current one.
are_fail2ban_files_the_same=$(compare_files "$FAIL2BAN_CONFIGURATION" "$FAIL2BAN_CONFIGURATION_TO_PASS")

if [[ "$are_fail2ban_files_the_same" != "true" ]]; then
    sudo cp -f "$FAIL2BAN_CONFIGURATION_TO_PASS" "$FAIL2BAN_CONFIGURATION"
    log_success "Fail2ban configuration applied."
else
    log_info "Fail2ban configuration already up to date."
fi

# Apply the chosen SSH port, shared with ssh.sh and firewall.sh via state.sh.
# fail2ban's sshd jail otherwise resolves its ban target through the "ssh"
# service name, which means port 22, and would silently miss the real port.
ssh_port=$(get_ssh_port)
change_configuration "port = " "$ssh_port" "$FAIL2BAN_CONFIGURATION"

# Enable and start the fail2ban service.
enable_service fail2ban
start_service fail2ban

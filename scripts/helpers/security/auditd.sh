#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
AUDITD_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$AUDITD_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$AUDITD_SCRIPT_DIRECTORY/../functions/filesystem.sh"
source "$AUDITD_SCRIPT_DIRECTORY/../functions/services.sh"
source "$AUDITD_SCRIPT_DIRECTORY/../functions/logs.sh"

# Install audit daemon.
install_packages "$AUDITD_SCRIPT_DIRECTORY/../../packages/security/auditd.txt" "$AUR_PACKAGE_MANAGER" "Installing audit daemon..."

# Check if audit rules directory exists.
if [ ! -d "/etc/audit/rules.d" ]; then
    sudo mkdir -p /etc/audit/rules.d
fi

# Copy each rule file if it differs from source.
for rule_file in "$AUDITD_SCRIPT_DIRECTORY/../../configurations/security/auditd/rules.d"/*.rules; do
    if [ -f "$rule_file" ]; then
        rule_name=$(basename "$rule_file")
        target_file="/etc/audit/rules.d/$rule_name"

        are_files_the_same=$(compare_files "$target_file" "$rule_file")
        if [ "$are_files_the_same" != "true" ]; then
            sudo cp -f "$rule_file" "$target_file"
            log_success "Audit rule $rule_name applied."
        else
            log_info "Audit rule $rule_name already up to date."
        fi
    fi
done

# Load rules and restart auditd if changes were made.
sudo augenrules --load
enable_service "auditd"
start_service "auditd"
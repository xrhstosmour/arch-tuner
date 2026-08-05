#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
AIDE_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$AIDE_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$AIDE_SCRIPT_DIRECTORY/../functions/filesystem.sh"
source "$AIDE_SCRIPT_DIRECTORY/../functions/logs.sh"

# Install aide integrity monitoring.
install_packages "$AIDE_SCRIPT_DIRECTORY/../../packages/security/aide.txt" "$AUR_PACKAGE_MANAGER" "Installing AIDE integrity monitoring..."

# Check if AIDE configuration needs to be installed.
if [ ! -d "/etc/aide" ]; then
    sudo mkdir -p /etc/aide
fi

# Copy AIDE configuration if it differs from the source.
are_files_the_same=$(compare_files "/etc/aide/aide.conf" "$AIDE_SCRIPT_DIRECTORY/../../configurations/security/aide/aide.conf")
if [ "$are_files_the_same" != "true" ]; then
    sudo cp -f "$AIDE_SCRIPT_DIRECTORY/../../configurations/security/aide/aide.conf" "/etc/aide/aide.conf"
    log_success "AIDE configuration applied."
else
    log_info "AIDE configuration already up to date."
fi

# Check if AIDE database exists, if not initialize it.
if [ ! -f "/var/lib/aide/aide.db.gz" ]; then
    log_info "Initializing AIDE database..."
    sudo aide --init
    sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
    log_success "AIDE database initialized."
fi
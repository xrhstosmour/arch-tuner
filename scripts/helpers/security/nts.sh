#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
NTS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$NTS_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$NTS_SCRIPT_DIRECTORY/../functions/filesystem.sh"
source "$NTS_SCRIPT_DIRECTORY/../functions/services.sh"

# Initialize a flag indicating if an encrypted network time security change has been made.
nts_changes_made=1

# Encrypted network time security constant configuration variables.
NTS_CONFIGURATION_DIRECTORY="/etc/chrony/"
NTS_SYSTEM_CONFIGURATION_DIRECTORY="/etc/sysconfig"
NTS_CONFIGURATION="/etc/chrony/chrony.conf"
NTS_CONFIGURATION_TO_PASS="$NTS_SCRIPT_DIRECTORY/../../configurations/security/network/time.conf"
NTS_SYSTEM_CONFIGURATION="/etc/sysconfig/chronyd"

# Install encrypted network time security.
install_packages "chrony" "$AUR_PACKAGE_MANAGER" "Installing encrypted network time security..."

# Copy the configuration file only if it is not the same as the current one.
are_nts_files_the_same=$(compare_files "$NTS_CONFIGURATION" "$NTS_CONFIGURATION_TO_PASS")
if [ "$are_nts_files_the_same" = "false" ]; then
    log_info "Configuring encrypted network time security..."
    sudo mkdir -p "$NTS_CONFIGURATION_DIRECTORY"
    sudo cp -f "$NTS_CONFIGURATION_TO_PASS" "$NTS_CONFIGURATION"
    sudo chmod 644 "$NTS_CONFIGURATION"
    sudo chown root:root "$NTS_CONFIGURATION"

    # Set the nts_changes_made flag to 0 (true).
    nts_changes_made=0
fi

# TODO: Try using the `change_configuration` function.
# Add the seccomp filter option to the environment file only if not exists.
if ! grep -q 'OPTIONS="-F 1"' "$NTS_SYSTEM_CONFIGURATION" 2>/dev/null; then
    log_info "Limiting access to encrypted network time security application..."
    sudo mkdir -p "$NTS_SYSTEM_CONFIGURATION_DIRECTORY"
    echo 'OPTIONS="-F 1"' | sudo tee "$NTS_SYSTEM_CONFIGURATION" >/dev/null

    # Set the nts_changes_made flag to 0 (true).
    nts_changes_made=0
fi

# Restart the network time security to apply the changes.
if [ $nts_changes_made -eq 0 ]; then
    stop_service "chronyd" "Stopping encrypted NTS service..."
    start_service "chronyd" "Starting encrypted NTS service..."
    enable_service "chronyd" "Enabling encrypted NTS service..."
fi

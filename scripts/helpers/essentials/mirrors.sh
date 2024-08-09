#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
MIRRORS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions and flags.
source "$MIRRORS_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$MIRRORS_SCRIPT_DIRECTORY/../functions/filesystem.sh"
source "$MIRRORS_SCRIPT_DIRECTORY/../functions/services.sh"
source "$MIRRORS_SCRIPT_DIRECTORY/../../core/flags.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Define the rate-mirrors configuration file, command and service.
RATE_MIRRORS_CONFIGURATION="$MIRRORS_SCRIPT_DIRECTORY/../../configurations/essentials/mirrors/rate-mirrors.conf"
RATE_MIRRORS_COMMAND=$(cat "$RATE_MIRRORS_CONFIGURATION")
RATE_MIRRORS_SERVICE="refresh-mirrors-list.service"
RATE_MIRRORS_SERVICE_FILE="/etc/systemd/system/$RATE_MIRRORS_SERVICE"

# Install mirror list manager.
install_packages "rate-mirrors-bin" "$AUR_PACKAGE_MANAGER" "Installing mirror list manager..."

# If the rate-mirrors service file does not exist, create it.
if [ ! -f "$RATE_MIRRORS_SERVICE_FILE" ]; then
    log_info "Adding mirror list auto refresh command to the root user's crontab..."
    start_service "cronie" "Starting crontab service..."
    enable_service "cronie" "Enabling crontab service..."
    (crontab -l 2>/dev/null; echo "@reboot $RATE_MIRRORS_COMMAND") | sudo crontab -

    log_info "Creating mirror list auto refresh service..."
    echo "[Unit]
        Description=Mirror list auto refresh service on startup

        [Service]
        ExecStart=/bin/bash -c '$RATE_MIRRORS_COMMAND'
        Type=oneshot
        RemainAfterExit=yes

        [Install]
        WantedBy=multi-user.target" | sudo tee "$RATE_MIRRORS_SERVICE_FILE" >/dev/null

    log_info "Configuring mirror list..."
    sudo "$RATE_MIRRORS_COMMAND"
fi

# Start and enable mirror list auto update service if it is not already active/enabled.
start_service "$RATE_MIRRORS_SERVICE" "Starting mirror list auto refresh service..."
enable_service "$RATE_MIRRORS_SERVICE" "Enabling mirror list auto refresh service..."

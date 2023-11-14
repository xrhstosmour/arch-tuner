#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
GREETER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$GREETER_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$GREETER_SCRIPT_DIRECTORY/../functions/services.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variables for greeter configuration.
GREETER_PACKAGE="ly"
GREETER_SERVICE="/etc/systemd/system/display-manager.service"
GREETER_CONFIGURATION="/etc/ly/config.ini"
GREETER_BLANK_PASSWORD="blank_password"
GREETER_BLANK_PASSWORD_TRUE="blank_password = true"

# Check if another greeter is already enabled.
if [ -L "$GREETER_SERVICE" ]; then
    existing_greeter=$(readlink "$GREETER_SERVICE")
    log_info "Disabling $existing_greeter greeter..."
    sudo systemctl disable "$existing_greeter"
fi

# Install display manager.
install_packages "$GREETER_PACKAGE" "$AUR_PACKAGE_MANAGER" "Installing display manager..."

# Enable display manager.
enable_service "$GREETER_PACKAGE" "Enabling display manager..."

# Uncomment any line that contains 'blank_password'.
sudo sed -i "/#.*$GREETER_BLANK_PASSWORD/s/^#//" "$GREETER_CONFIGURATION"

# Check if the setting already exists and if it matches the desired value.
if grep -q "$GREETER_BLANK_PASSWORD" "$GREETER_CONFIGURATION"; then
    if ! grep -q "^$GREETER_BLANK_PASSWORD_TRUE" "$GREETER_CONFIGURATION"; then
        log_info "Setting greeter blank password to true..."
        sudo sed -i "/^$GREETER_BLANK_PASSWORD/c\\$GREETER_BLANK_PASSWORD_TRUE" "$GREETER_CONFIGURATION"
    fi
else
    # If the setting doesn't exist at all, append it to the configuration file.
    log_info "Adding display manager blank password true..."
    echo "$GREETER_BLANK_PASSWORD_TRUE" | sudo tee -a "$GREETER_CONFIGURATION" >/dev/null
fi

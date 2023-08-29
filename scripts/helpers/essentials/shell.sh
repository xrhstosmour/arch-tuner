#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Import functions and constant variables.
source ../functions.sh
source ../../core/constants.sh

# Constant variables for changing and configuring shell.
FISH_SHELL="fish"
FISH_BINARY_DIRECTORY="/usr/bin/fish"
FISH_CONFIGURATION_DIRECTORY="~/.config/fish"
FISH_ALIASES_DIRECTORY="~/.config/fish/conf.d/"
FISH_CONFIGURATION="~/.config/fish/config.fish"
FISH_CONFIGURATION_TO_PASS="./configurations/shell/configuration.fish"
FISH_ALIASES="~/.config/fish/conf.d/abbr.fish"
FISH_ALIASES_TO_PASS="./configurations/shell/aliases.fish"

# Install fish package.
install_packages "$FISH_SHELL" "$AUR_PACKAGE_MANAGER" ""Installing shell...""

# Configuring shell.
if [ ! -f "$FISH_CONFIGURATION" ] || ! diff "$FISH_CONFIGURATION_TO_PASS" "$FISH_CONFIGURATION" &>/dev/null; then
    log_info "Configuring shell..."
    mkdir -p "$FISH_CONFIGURATION_DIRECTORY" && cp -f "$FISH_CONFIGURATION_TO_PASS" "$FISH_CONFIGURATION"
fi

# Configuring shell aliases.
if [ ! -f "$FISH_ALIASES" ] || ! diff "$FISH_ALIASES_TO_PASS" "$FISH_ALIASES" &>/dev/null; then
    log_info "Configuring shell aliases..."
    mkdir -p "$FISH_ALIASES_DIRECTORY" && cp -f "$FISH_ALIASES_TO_PASS" "$FISH_ALIASES"
fi

# Setting default shell.
current_shell=$(basename "$SHELL")
if [ "$current_shell" != "$FISH_SHELL" ]; then
    log_info "Setting default shell..."
    grep -qxF "$FISH_BINARY_DIRECTORY" /etc/shells || echo "$FISH_BINARY_DIRECTORY" | sudo tee -a /etc/shells >/dev/null
    sudo chsh -s "$FISH_BINARY_DIRECTORY" $USER
else
    log_info "$FISH_SHELL is already the default shell!"
fi

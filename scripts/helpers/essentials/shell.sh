#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SHELL_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$SHELL_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$SHELL_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variables for changing and configuring shell.
FISH_SHELL="fish"
FISH_BINARY_DIRECTORY="/usr/bin/fish"
FISH_CONFIGURATION_DIRECTORY="$HOME/.config/fish"
FISH_ALIASES_DIRECTORY="$HOME/.config/fish/conf.d/"
FISH_CONFIGURATION="$HOME/.config/fish/config.fish"
FISH_CONFIGURATION_TO_PASS="$SHELL_SCRIPT_DIRECTORY/../../configurations/essentials/shell/configuration.fish"
FISH_ALIASES="$HOME/.config/fish/conf.d/abbr.fish"
FISH_ALIASES_TO_PASS="$SHELL_SCRIPT_DIRECTORY/../../configurations/essentials/shell/aliases.fish"

# Install shell package.
install_packages "$FISH_SHELL" "$AUR_PACKAGE_MANAGER" "Installing shell..."

# Configure shell.
are_fish_configuration_files_the_same=$(compare_files "$FISH_CONFIGURATION" "$FISH_CONFIGURATION_TO_PASS")
if [ "$are_fish_configuration_files_the_same" = "false" ]; then
    log_info "Configuring shell..."
    mkdir -p "$FISH_CONFIGURATION_DIRECTORY"
    cp -f "$FISH_CONFIGURATION_TO_PASS" "$FISH_CONFIGURATION"
fi

# Configure shell aliases.
are_fish_aliases_files_the_same=$(compare_files "$FISH_ALIASES" "$FISH_ALIASES_TO_PASS")
if [ "$are_fish_aliases_files_the_same" = "false" ]; then
    log_info "Configuring shell aliases..."
    mkdir -p "$FISH_ALIASES_DIRECTORY"
    cp -f "$FISH_ALIASES_TO_PASS" "$FISH_ALIASES"
fi

# Set default shell.
current_shell=$(basename "$SHELL")
if [ "$current_shell" != "$FISH_SHELL" ]; then
    log_info "Setting default shell..."
    grep -qxF "$FISH_BINARY_DIRECTORY" /etc/shells || echo "$FISH_BINARY_DIRECTORY" | sudo tee -a /etc/shells >/dev/null
    sudo chsh -s "$FISH_BINARY_DIRECTORY" $USER
fi

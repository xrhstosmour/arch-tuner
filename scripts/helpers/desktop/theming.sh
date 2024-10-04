#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
THEMING_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$THEMING_SCRIPT_DIRECTORY/../functions/packages.sh"

# Constant variables for the file paths containing the themes, icons, and cursors to install.
THEMES="$THEMING_SCRIPT_DIRECTORY/../../packages/desktop/themes.txt"
ICONS="$THEMING_SCRIPT_DIRECTORY/../../packages/desktop/icons.txt"
CURSORS="$THEMING_SCRIPT_DIRECTORY/../../packages/desktop/cursors.txt"

# Check if at least one theme is not installed.
are_theme_packages_installed=$(are_packages_installed "$THEMES" "$AUR_PACKAGE_MANAGER")
if [ "$are_theme_packages_installed" = "false" ]; then
    log_info "Installing themes..."

    # Install themes.
    install_packages "$THEMES" "$AUR_PACKAGE_MANAGER"
fi

# Check if at least one icon is not installed.
are_icon_packages_installed=$(are_packages_installed "$ICONS" "$AUR_PACKAGE_MANAGER")
if [ "$are_icon_packages_installed" = "false" ]; then
    log_info "Installing icons..."

    # Install icons.
    install_packages "$ICONS" "$AUR_PACKAGE_MANAGER"
fi

# Check if at least one cursor is not installed.
are_cursor_packages_installed=$(are_packages_installed "$CURSORS" "$AUR_PACKAGE_MANAGER")
if [ "$are_cursor_packages_installed" = "false" ]; then
    log_info "Installing cursors..."

    # Install cursors.
    install_packages "$CURSORS" "$AUR_PACKAGE_MANAGER"
fi

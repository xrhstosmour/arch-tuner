#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
AUR_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$AUR_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$AUR_SCRIPT_DIRECTORY/../functions/ui.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Get the user's choice about AUR helper.
aur_helper=$(choose_aur_helper)

# Change the 'constant' value to the one user choosed.
change_flag_value "AUR_PACKAGE_MANAGER" "$aur_helper" "$AUR_SCRIPT_DIRECTORY/../../core/constants.sh"

# Constant variables for installing and configuring the AUR helper.
AUR_DIRECTORY="$aur_helper"
AUR_GIT_URL="https://aur.archlinux.org/$aur_helper.git"
PARU_CONFIGURATION="/etc/paru.conf"

# Install AUR helper.
if ! command -v "$AUR_PACKAGE_MANAGER" &>/dev/null; then

    # Delete old AUR directory, if it exists.
    if [ -d "$AUR_DIRECTORY" ]; then
        log_info "Deleting old $AUR_DIRECTORY directory..."
        rm -rf "$AUR_DIRECTORY"
    fi

    # Execute needed configuration before installing the AUR helper.
    case $aur_helper in
    paru)

        # Delete rust package manager, if it exists.
        is_rust_installed=$(are_packages_installed "rust" "$ARCH_PACKAGE_MANAGER")
        if [ "$is_rust_installed" = "true" ]; then
            log_info "Deleting rust package manager..."
            sudo "$ARCH_PACKAGE_MANAGER" -Rns --noconfirm rust 2>/dev/null || true
        fi

        # Install rustup package.
        install_packages "rustup" "$ARCH_PACKAGE_MANAGER"

        # Check if rustup is already at stable version.
        current_rustup_version=$(rustup show active-toolchain)
        if [[ "$current_rustup_version" != "stable"* ]]; then

            # Changing to stable rust version.
            log_info "Changing to stable rust version..."
            rustup default stable
        fi
        ;;
    yay)
        :
        ;;
    esac

    # Proceed with installation.
    log_info "Installing $AUR_PACKAGE_MANAGER AUR helper..."
    git clone $AUR_GIT_URL
    cd $AUR_DIRECTORY
    makepkg -si --noconfirm
    cd ..
    rm -rf $AUR_DIRECTORY
fi

# Configure the AUR helper.
case $aur_helper in
paru)

    # Configure AUR helper.
    if ! grep -qxF 'SkipReview' "$PARU_CONFIGURATION"; then
        log_info "Configuring $AUR_PACKAGE_MANAGER package manager..."
    fi

    # Skip review messages.
    if ! grep -qxF 'SkipReview' $PARU_CONFIGURATION; then
        log_info "Skipping review messages..."
        echo 'SkipReview' | sudo tee -a $PARU_CONFIGURATION >/dev/null
    fi
    ;;
yay)
    :
    ;;
esac

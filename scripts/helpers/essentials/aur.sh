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

# Check if an AUR helper is already installed.
aur_helper=""
if command -v paru &>/dev/null; then

    # Change the 'constant' value to "paru".
    aur_helper="paru"
    change_flag_value "AUR_PACKAGE_MANAGER" "paru" "$AUR_SCRIPT_DIRECTORY/../../core/constants.sh"
elif command -v yay &>/dev/null; then

    # Change the 'constant' value to "paru".
    aur_helper="yay"
    change_flag_value "AUR_PACKAGE_MANAGER" "yay" "$AUR_SCRIPT_DIRECTORY/../../core/constants.sh"
else

    # Get the user's choice about AUR helper.
    aur_helper=$(choose_aur_helper)

    # Change the 'constant' value to the one user choosed.
    change_flag_value "AUR_PACKAGE_MANAGER" "$aur_helper" "$AUR_SCRIPT_DIRECTORY/../../core/constants.sh"

    # Constant variables for installing and configuring the AUR helper.
    AUR_DIRECTORY="$aur_helper"
    AUR_GIT_URL="https://aur.archlinux.org/$aur_helper.git"

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
    log_info "Installing $aur_helper AUR helper..."
    git clone $AUR_GIT_URL
    cd $AUR_DIRECTORY
    makepkg -si --noconfirm
    cd ..
    rm -rf $AUR_DIRECTORY
fi

# Configure the AUR helper.
case $aur_helper in
paru)

    # Declare the configuration options of the AUR helper we want to set.
    declare -a CONFIGURATION_OPTIONS=("BottomUp" "Devel" "Provides" "PgpFetch" "CombinedUpgrade" "FailFast" "SudoLoop" "SkipReview")

    # Constant variable for the paru AUR helper configuration file.
    PARU_CONFIGURATION="/etc/paru.conf"

    # Check if at least one configuration option does not exist or is commented out.
    configuration_option_missing=false
    for configuration_option in "${CONFIGURATION_OPTIONS[@]}"; do
        if ! grep -qxF "$configuration_option" "$PARU_CONFIGURATION"; then
            configuration_option_missing=true
            break
        fi
    done

    # Configure AUR helper if any configuration option is missing.
    if [ "$configuration_option_missing" = true ]; then
        log_info "Configuring $aur_helper package manager..."

        # Add each configuration option if not already present.
        for configuration_option in "${CONFIGURATION_OPTIONS[@]}"; do
            if ! grep -qxF "$configuration_option" "$PARU_CONFIGURATION"; then
                log_info "Adding '$configuration_option' to $AUR_PACKAGE_MANAGER configuration..."
                echo "$configuration_option" | sudo tee -a "$PARU_CONFIGURATION" >/dev/null
            fi
        done
    fi
    ;;
yay)
    :
    ;;
esac

# TODO: Clean AUR cache configuration using paccache.

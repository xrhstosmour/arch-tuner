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
source "$AUR_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Check if an AUR helper is already installed.
    aur_helper=""
    if command -v paru &>/dev/null; then

        # Change the 'constant' value to "paru".
        aur_helper="paru"
        change_flag_value "AUR_PACKAGE_MANAGER" "paru"
    elif command -v yay &>/dev/null; then

        # Change the 'constant' value to "yay".
        aur_helper="yay"
        change_flag_value "AUR_PACKAGE_MANAGER" "yay"
    else

        # Get the user's choice about AUR helper.
        declare -a AUR_OPTIONS=("paru" "yay")
        aur_helper=$(choose_option "Choose an AUR helper" "${AUR_OPTIONS[@]}")

        # Change the 'constant' value to the one user chose.
        change_flag_value "AUR_PACKAGE_MANAGER" "$aur_helper"
    fi

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
    # ? AUR packages are unsigned, user-submitted content, there is no PGP/signature verification
    # ? available for a PKGBUILD, unlike official repository packages. Bootstrapping the AUR helper
    # ? itself cannot go through an AUR helper's own review/verification options, since none is
    # ? installed yet. Only the HTTPS transport to aur.archlinux.org is verified here.
    log_info "Installing $aur_helper AUR helper..."
    git clone "$AUR_GIT_URL"
    cd "$AUR_DIRECTORY"
    if [ ! -f PKGBUILD ]; then
        log_error "PKGBUILD not found after cloning $AUR_DIRECTORY, aborting installation!"
        exit 1
    fi
    makepkg -si --noconfirm
    cd ..
    rm -rf "$AUR_DIRECTORY"

# Configure the AUR helper.
case $aur_helper in
paru)

    # Declare the configuration options of the AUR helper we want to set.
    declare -a CONFIGURATION_OPTIONS=("BottomUp" "Devel" "Provides" "PgpFetch" "CombinedUpgrade" "FailFast" "SudoLoop" "SkipReview")

    # Constant variable for the paru AUR helper configuration file.
    PARU_CONFIGURATION="$HOME/.config/paru/paru.conf"

    # Add CleanMethod = KeepInstalled to paru configuration.
    if [ -f "$PARU_CONFIGURATION" ]; then
        if ! grep -qxF "CleanMethod = KeepInstalled" "$PARU_CONFIGURATION"; then
            log_info "Adding CleanMethod = KeepInstalled to $aur_helper configuration..."
            change_configuration "CleanMethod" " = KeepInstalled" "$PARU_CONFIGURATION"
        else
            log_info "CleanMethod = KeepInstalled already configured."
        fi
    fi

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
                change_configuration "$configuration_option" "" "$PARU_CONFIGURATION"
            fi
        done
    fi
    ;;
yay)
    :
    ;;
esac

# Clean the pacman package cache, keeping only the most recent version of
# each package. AUR packages install through pacman too, so their old
# cached versions build up here just like official repository packages.
install_packages "pacman-contrib" "$ARCH_PACKAGE_MANAGER" "Installing cache clearing package..."
sudo paccache -r

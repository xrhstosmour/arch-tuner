#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
PACKAGES_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PACKAGES_SCRIPT_DIRECTORY/logs.sh"
source "$PACKAGES_SCRIPT_DIRECTORY/strings.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

# Function to populate an associative array (passed by name) with every package
# currently installed via the given package manager, queried once.
# populate_installed_packages_set "package_manager" "array_name"
populate_installed_packages_set() {
    local package_manager="$1"
    local -n installed_packages_set_ref="$2"

    local installed_package
    while IFS= read -r installed_package; do
        # shellcheck disable=SC2034 # Reason: nameref, written into the caller's array by name, not read here.
        installed_packages_set_ref["$installed_package"]=1
    done < <("$package_manager" -Qq)
}

# Function to check if all packages are installed.
# The file should contain one package per line.
# The variable should contain packages separated by spaces.
# are_packages_installed "path/to/file.txt" "package_manager"
# are_packages_installed "$PACKAGES_TO_INSTALL" "package_manager"
are_packages_installed() {
    local input="$1"
    local package_manager="$2"
    local package_not_found=0

    # For a real package manager, list all installed packages once instead of
    # shelling out per package below. If no package manager is specified,
    # each package is checked individually via `command -v` below instead.
    local -A installed_packages_set=()
    if [ -n "$package_manager" ]; then
        case "$package_manager" in
        "$AUR_PACKAGE_MANAGER" | "$ARCH_PACKAGE_MANAGER")
            populate_installed_packages_set "$package_manager" installed_packages_set
            ;;
        *)
            log_error "Unsupported package manager: '$package_manager'"
            exit 1
            ;;
        esac
    fi

    # Check if the argument is a file.
    if [ -f "$input" ]; then
        # Read packages from file, each package separated by a new line.
        mapfile -t packages <"$input"
    else
        # Read packages from a space separated string.
        IFS=' ' read -ra packages <<<"$input"
    fi

    # Loop through the packages and check if they are installed.
    for package in "${packages[@]}"; do

        # Trim leading and trailing whitespace and skip if it's a comment or empty.
        package=$(echo "$package" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ "$package" == \#* ]] || [[ -z "$package" ]]; then
            continue
        fi

        # Check if the package is already installed.
        if [ -n "$package_manager" ]; then
            if [[ -z "${installed_packages_set[$package]+x}" ]]; then
                package_not_found=1
            fi
        elif ! command -v "$package" >/dev/null 2>&1; then
            package_not_found=1
        fi
    done

    # Return false if at least one package is missing.
    if [ $package_not_found -eq 1 ]; then
        echo "false"
    else
        echo "true"
    fi
}

# Function to install a package if it is not already installed.
# process_package "package" "install_command" "message" "installed_packages_set_array_name"
process_package() {
    local package
    package=$(trim_string "$1")
    local install_command="$2"
    local message="${3:-"Installing '$package' package..."}"
    local -n installed_set_ref="$4"

    # Skip if it's a comment or empty.
    [[ "$package" == \#* ]] || [[ -z "$package" ]] && return

    # If the package starts with '!', add flags to skip test checks.
    if [[ "$package" == !* ]]; then
        package="${package:1}"
        install_command="$install_command --mflags --nocheck"

        # Change the message if no other message was provided.
        if [ -z "$3" ]; then
            message="Installing '$package' package without tests..."
        fi
    fi

    # Install package if it is not already installed.
    if [[ -z "${installed_set_ref[$package]+x}" ]]; then

        # Print message.
        log_info "$message"

        # Install the package.
        $install_command "$package"
    fi
}

# Function to install packages from file or variable choosing the appropriate package manager.
# The file should contain one package per line.
# The variable should contain packages separated by spaces.
# install_packages "path/to/file.txt" "package_manager"
# install_packages "$PACKAGES_TO_INSTALL" "package_manager"
install_packages() {
    local input="$1"
    local manager="$2"
    local message="$3"
    local install_command=""

    # Determine the installation command based on the chosen package manager.
    case "$manager" in
    "$AUR_PACKAGE_MANAGER")
        install_command="$AUR_PACKAGE_MANAGER -S --noconfirm --needed"
        ;;
    "$ARCH_PACKAGE_MANAGER")
        install_command="sudo $ARCH_PACKAGE_MANAGER -S --noconfirm --needed"
        ;;
    *)
        log_error "Unsupported package manager: '$manager'"
        exit 1
        ;;
    esac

    # List installed packages once for this whole batch instead of once per package below.
    local -A installed_packages_set=()
    populate_installed_packages_set "$manager" installed_packages_set

    # Determine if the input is a file or variable and act accordingly.
    if [[ -r "$input" ]]; then
        while IFS= read -r package; do
            process_package "$package" "$install_command" "$message" installed_packages_set
        done <"$input"
    else
        IFS=' ' read -ra packages_array <<<"$input"
        for package in "${packages_array[@]}"; do
            process_package "$package" "$install_command" "$message" installed_packages_set
        done
    fi
}

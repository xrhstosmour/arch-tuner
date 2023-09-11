#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
PACKAGES_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PACKAGES_SCRIPT_DIRECTORY/logs.sh"
source "$PACKAGES_SCRIPT_DIRECTORY/strings.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

# Function to check if all packages are installed.
# The file should contain one package per line.
# The variable should contain packages separated by spaces.
# are_packages_installed "path/to/file.txt" "package_manager"
# are_packages_installed "$PACKAGES_TO_INSTALL" "package_manager"
are_packages_installed() {
    local input="$1"
    local package_manager="$2"
    local package_not_found=0

    # Determine the installation command based on the chosen package manager.
    case "$package_manager" in
    "$AUR_PACKAGE_MANAGER")
        local query_command="$AUR_PACKAGE_MANAGER -Q"
        ;;
    "$ARCH_PACKAGE_MANAGER")
        local query_command="$ARCH_PACKAGE_MANAGER -Q"
        ;;
    "")
        # If no package manager is specified, we'll use `command -V`.
        query_command="command -v"
        ;;
    *)
        log_error "Unsupported package manager: '$package_manager'"
        exit 1
        ;;
    esac

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
        if ! $query_command "$package" >/dev/null 2>&1; then
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
# process_package "package" "install_command" "message"
process_package() {
    local package="$(trim_string "$1")"
    local install_command="$2"
    local message="${4:-"Installing '$package' package..."}"

    # Skip if it's a comment or empty.
    [[ "$package" == \#* ]] || [[ -z "$package" ]] && return

    # Install package if it is not already installed.
    is_package_installed=$(are_packages_installed "$package" "$manager")
    if [ "$is_package_installed" = "false" ]; then

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

    # Determine if the input is a file or variable and act accordingly.
    if [[ -r "$input" ]]; then
        while IFS= read -r package; do
            process_package "$package" "$install_command" "$message"
        done <"$input"
    else
        IFS=' ' read -ra packages_array <<<"$input"
        for package in "${packages_array[@]}"; do
            process_package "$package" "$install_command" "$message"
        done
    fi
}

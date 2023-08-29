#!/bin/bash

# Import constant variables.
source ../core/constants.sh

# Function to log an info message.
# log_info "Info message to log"
log_info() {
    info="$1"
    echo -e "\n${BOLD_CYAN}""$info""${NO_COLOR}"
}

# Function to log a warning message.
# log_warning "Warning message to log"
log_warning() {
    warning="$1"
    echo -e "\n${BOLD_YELLOW}""$warning""${NO_COLOR}"
}

# Function to log an error message.
# log_error "Warning message to log"
log_error() {
    error="$1"
    echo -e "\n${BOLD_RED}""$error""${NO_COLOR}"
}

# Function to check if a line exists in a file and add it if it does not.
# append_line_to_file "/file/path/with.extension" "Line To Append" "Message to print if the line is appended."
append_line_to_file() {
    file_path="$1"
    line_to_append="$2"
    message="$3"

    if ! grep -qxF "$line_to_append" "$file_path"; then

        # Print message if it exists.
        if [ -n "$message" ]; then
            log_info "$message"
        fi

        # Append line to file.
        echo "$line_to_append" | sudo tee -a "$file_path" >/dev/null

        # Return 0 (true) to indicate that a change was made.
        return 0
    fi

    # Return 1 (false) to indicate that no change was made.
    return 1
}

# Function to add options to a mount point.
# add_mount_options "/path/to/mount/point" "option1,opption2,option3"
add_mount_options() {
    local mount_point="$1"
    local options="$2"

    # Check if the options are already present and if not add them.
    if ! grep -q " $mount_point .*defaults,.*$options" /etc/fstab; then
        if grep -q " $mount_point " /etc/fstab; then
            log_info "Adding options $options to mount point $mount_point..."
            sudo sed -i "s|\($mount_point .*\) defaults |\1 defaults,$options |" /etc/fstab

            # Return 0 (true) to indicate that a change was made.
            return 0
        fi
    fi

    # Return 1 (false) to indicate that no change was made.
    return 1
}

# Function to trim a string.
# trim_string "string_to_trim"
trim_string() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Function to check if there is at least one missing package.
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
        local query_command="$AUR_PACKAGE_MANAGER -Qs"
        ;;
    "$ARCH_PACKAGE_MANAGER")
        local query_command="$ARCH_PACKAGE_MANAGER -Qs"
        ;;
    *)
        log_error "Unsupported package manager: $package_manager"
        return 1
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

    # Return 0 (true) if at least one package is missing.
    if [ $package_not_found -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

# Function to install a package if it is not already installed.
# process_package "package" "install_command" "message"
process_package() {
    local package="$(trim_string "$1")"
    local install_command="$2"
    local message="$4"

    # Skip if it's a comment or empty.
    [[ "$package" == \#* ]] || [[ -z "$package" ]] && return

    # Check if the package is already installed.
    if are_packages_installed "$package" "$manager"; then

        # Print message if it is valid.
        if [ -n "$message" ]; then
            log_info "$message"
        else
            log_info "Installing '$package'..."
        fi

        # Install the package.
        $install_command "$package"
    else
        log_warning "Package '$package' is already installed!"
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
        log_error "Unsupported package manager: $manager"
        return 1
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

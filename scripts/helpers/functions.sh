#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
FUNCTIONS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import constant variables.
source "$FUNCTIONS_SCRIPT_DIRECTORY/../core/constants.sh"

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
    *)
        log_error "Unsupported package manager: '$package_manager'"
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

    # Return 1 (false) if at least one package is missing.
    if [ $package_not_found -eq 1 ]; then
        return 1
    else
        return 0
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
    if ! are_packages_installed "$package" "$manager"; then

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

# Function to compare two files.
# compare_files "target_file" "source_file"
compare_files() {
    local target_file=$1
    local source_file=$2

    # If the target file does not exist or is different from the source file, return 1 (false).
    # If the target file exists and is the same as the source file, return 0 (true).
    if [ ! -f "$target_file" ] || ! diff "$source_file" "$target_file" &>/dev/null; then
        return 1
    else
        return 0
    fi
}

# Function to update system.
# update_system
update_system() {

    # Update package databases.
    sudo pacman -Sy

    # Check if any package is upgradable.
    upgradable=$(pacman -Qu) || true

    # Check if 'archlinux-keyring' package is upgradable.
    upgradable_keyring=$(echo "$upgradable" | grep archlinux-keyring) || true

    # Update 'archlinux-keyring' package if it needs an update.
    if [[ -n "$upgradable_keyring" ]]; then
        log_info "Updating archlinux-keyring..."
        sudo pacman -S --noconfirm --needed archlinux-keyring
    fi

    # Update system if any package is upgradable.
    if [[ -n "$upgradable" ]]; then
        log_info "Updating system..."
        sudo pacman -Su --noconfirm --needed
    fi
}

# Function to give execution permission to scripts.
give_execution_permission_to_scripts() {

    # Take all the arguments as an array.
    local scripts=("$@")

    # Pop the last element from the array and assign it to message.
    local message="${scripts[-1]:-"Giving execution permission to needed scripts."}"

    # Remove the last element from the array.
    unset 'scripts[${#scripts[@]}-1]'

    # Initialize a variable to track if logging is needed.
    local need_to_log=false

    # First loop to check if any script needs execute permission.
    for script in "${scripts[@]}"; do
        if [[ ! -x "$script" ]]; then

            # Set the flag to true as at least one script needs permission.
            need_to_log=true
            break
        fi
    done

    # Log only if at least one script needed permission change.
    if [ "$need_to_log" = true ]; then
        log_info "$message"
    fi

    # Second loop to actually give execute permission if not already set.
    for script in "${scripts[@]}"; do
        if [[ ! -x "$script" ]]; then
            chmod +x "$script"
        fi
    done
}

# Function to enable a service.
# enable_service "service_name" "message"
enable_service() {
    local service_name="$1"
    local message="${2:-"Enabling $service_name service..."}"

    # Check if the service is enabled
    if ! systemctl is-enabled --quiet "$service_name"; then
        log_info "$message"
        sudo systemctl enable "$service_name"

        # Return 0 (true) to indicate that the service was enabled.
        return 0
    else
        # Return 1 (false) to indicate that the service was already enabled.
        return 1
    fi
}

# Function to start a service.
# start_service "service_name" "message"
start_service() {
    local service_name="$1"
    local message="${2:-"Starting $service_name service..."}"

    # Check if the service is active
    if ! systemctl is-active --quiet "$service_name"; then
        log_info "$message"
        sudo systemctl start "$service_name"
    fi
}

# Function to stop a service.
# stop_service "service_name" "message"
stop_service() {
    local service_name="$1"
    local message="${2:-"Stoping $service_name service..."}"

    # Check if the service is active
    if systemctl is-active --quiet "$service_name"; then
        log_info "$message"
        sudo systemctl stop "$service_name"
    fi
}

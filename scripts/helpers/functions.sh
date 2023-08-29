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
            echo -e "\n${BOLD_CYAN}""$message""${NO_COLOR}"
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
            echo -e "\n${BOLD_CYAN}Adding options $options to mount point $mount_point...${NO_COLOR}"
            sudo sed -i "s|\($mount_point .*\) defaults |\1 defaults,$options |" /etc/fstab

            # Return 0 (true) to indicate that a change was made.
            return 0
        fi
    fi

    # Return 1 (false) to indicate that no change was made.
    return 1
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

    # Determine the installation command based on the chosen package manager.
    case "$manager" in
    paru)
        local install_command="paru -S --noconfirm --needed"
        local query_command="paru -Qs"
        ;;
    pacman)
        local install_command="sudo pacman -S --noconfirm --needed"
        local query_command="pacman -Qs"
        ;;
    *)
        echo "Unsupported package manager: $manager"
        return 1
        ;;
    esac

    # A helper function to process and install a package.
    process_package() {
        local package="$1"

        # Trim leading and trailing whitespace and skip if it's a comment or empty.
        package=$(echo "$package" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ "$package" == \#* ]] || [[ -z "$package" ]]; then
            return
        fi

        # Check if the package is already installed
        if ! $query_command "$package" >/dev/null 2>&1; then

            # Print message if it exists.
            if [ -n "$message" ]; then
                echo -e "\n${BOLD_CYAN}""$message""${NO_COLOR}"
            else
                echo -e "\n${BOLD_CYAN}Installing '$package'...${NO_COLOR}"
            fi

            # Install the package.
            $install_command "$package"
        else
            echo -e "\n${BOLD_CYAN}Package '$package' is already installed!${NO_COLOR}"
        fi
    }

    # Determine if the input is a file or variable and act accordingly.
    if [[ -r "$input" ]]; then
        while IFS= read -r package; do
            process_package "$package"
        done <"$input"
    else
        IFS=' ' read -ra packages_array <<<"$input"
        for package in "${packages_array[@]}"; do
            process_package "$package"
        done
    fi
}

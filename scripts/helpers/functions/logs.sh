#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
LOGS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import constant variables.
source "$LOGS_SCRIPT_DIRECTORY/../../core/constants.sh"

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

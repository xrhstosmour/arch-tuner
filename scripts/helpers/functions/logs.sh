#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
LOGS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import constant variables.
source "$LOGS_SCRIPT_DIRECTORY/../../core/constants.sh"

# Function to log an info message.
# Usage:
#   log_info "Info message to log"
#   log_info -n "Info message to log without newline"
log_info() {
    local prefix="\n"
    if [[ "$1" == "-n" ]]; then
        prefix=""
        shift
    fi
    info="$1"
    echo -e "${prefix}${BOLD_CYAN}$info${NO_COLOR}" >&2
}

# Function to log a success message.
# Usage:
#   log_success "Success message to log"
#   log_success -n "Success message to log without newline"
log_success() {
    local prefix="\n"
    if [[ "$1" == "-n" ]]; then
        prefix=""
        shift
    fi
    success="$1"
    echo -e "${prefix}${BOLD_GREEN}$success${NO_COLOR}" >&2
}

# Function to log a warning message.
# Usage:
#   log_warning "Warning message to log"
#   log_warning -n "Warning message to log without newline"
log_warning() {
    local prefix="\n"
    if [[ "$1" == "-n" ]]; then
        prefix=""
        shift
    fi
    warning="$1"
    echo -e "${prefix}${BOLD_YELLOW}$warning${NO_COLOR}" >&2
}

# Function to log an error message.
# Usage:
#   log_error "Error message to log"
#   log_error -n "Error message to log without newline"
log_error() {
    local prefix="\n"
    if [[ "$1" == "-n" ]]; then
        prefix=""
        shift
    fi
    error="$1"
    echo -e "${prefix}${BOLD_RED}$error${NO_COLOR}" >&2
}

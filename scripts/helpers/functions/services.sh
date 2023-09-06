#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
SERVICES_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import constant variables.
source "$SERVICES_SCRIPT_DIRECTORY/../../core/constants.sh"

# Import log functions.
source "$PACKAGES_SCRIPT_DIRECTORY/logs.sh"

# Function to check if a service is active or not.
# Returns 0 if the service is active, 1 otherwise.
# is_service_active "service_name"
is_service_active() {
    local service_name="$1"

    if systemctl is-active --quiet "$service_name"; then
        # Return 0 (true) to indicate that the service is active.
        return 0
    else
        # Return 1 (false) to indicate that the service is not active.
        return 1
    fi
}

# Function to check if a service is enabled or not.
# Returns 0 if the service is enabled, 1 otherwise.
# is_service_enabled "service_name"
is_service_enabled() {
    local service_name="$1"

    if systemctl is-enabled --quiet "$service_name"; then
        # Return 0 (true) to indicate that the service is enabled.
        return 0
    else
        # Return 1 (false) to indicate that the service is not enabled.
        return 1
    fi
}

# Function to enable a service.
# enable_service "service_name" "message"
enable_service() {
    local service_name="$1"
    local message="${2:-"Enabling $service_name service..."}"

    # Check if the service is enabled
    if ! is_service_enabled "$service_name"; then
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
    if ! is_service_active "$service_name"; then
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

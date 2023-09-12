#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
SERVICES_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import log functions.
source "$SERVICES_SCRIPT_DIRECTORY/logs.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

# Function to check if a service is active or not.
# is_service_active "service_name"
is_service_active() {
    local service_name="$1"

    if sudo systemctl is-active --quiet "$service_name"; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to check if a service is enabled or not.
# is_service_enabled "service_name"
is_service_enabled() {
    local service_name="$1"

    if sudo systemctl is-enabled --quiet "$service_name"; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to enable a service.
# enable_service "service_name" "message"
enable_service() {
    local service_name="$1"
    local message="${2:-"Enabling $service_name service..."}"

    # Check if the service is enabled
    is_service_already_enabled=$(is_service_enabled "$service_name")
    if [ "$is_service_already_enabled" = "false" ]; then
        log_info "$message"
        sudo systemctl enable "$service_name"
    fi
}

# Function to start a service.
# start_service "service_name" "message"
start_service() {
    local service_name="$1"
    local message="${2:-"Starting $service_name service..."}"

    # Check if the service is already active.
    is_service_already_active=$(is_service_active "$service_name")
    if [ "$is_service_already_active" = "false" ]; then
        log_info "$message"
        sudo systemctl start "$service_name"
    fi
}

# Function to stop a service.
# stop_service "service_name" "message"
stop_service() {
    local service_name="$1"
    local message="${2:-"Stoping $service_name service..."}"

    # Check if the service is already active.
    is_service_already_active=$(is_service_active "$service_name")
    if [ "$is_service_already_active" = "true" ]; then
        log_info "$message"
        sudo systemctl stop "$service_name"
    fi
}

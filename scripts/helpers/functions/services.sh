#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
SERVICES_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import log functions.
source "$SERVICES_SCRIPT_DIRECTORY/logs.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

# Function to check if a service is active or not.
# is_service_active "service_name" "mode"
is_service_active() {
    local service_name="$1"

    # Default mode is system.
    local mode="${2:-system}"

    # Construct the systemctl command based on the mode.
    local systemctl_command="sudo systemctl"
    [ "$mode" = "user" ] && systemctl_command="systemctl --user"

    # Check if the service is active.
    if $systemctl_command is-active --quiet "$service_name"; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to check if a service is enabled or not.
# is_service_enabled "service_name" "mode"
is_service_enabled() {
    local service_name="$1"

    # Default mode is system.
    local mode="${2:-system}"

    # Construct the systemctl command based on the mode.
    local systemctl_command="sudo systemctl"
    [ "$mode" = "user" ] && systemctl_command="systemctl --user"

    # Check if the service is enabled.
    if $systemctl_command is-enabled --quiet "$service_name"; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to enable a service.
# enable_service "service_name" "message" "mode"
enable_service() {
    local service_name="$1"
    local message="${2:-"Enabling $service_name service..."}"

    # Default mode is system.
    local mode="${3:-system}"

    # Construct the systemctl command based on the mode.
    local systemctl_command="sudo systemctl"
    [ "$mode" = "user" ] && systemctl_command="systemctl --user"

    # Check if the service is enabled
    is_service_already_enabled=$(is_service_enabled "$service_name" "$mode")
    if [ "$is_service_already_enabled" = "false" ]; then
        log_info "$message"
        $systemctl_command enable "$service_name"
    fi
}

# Function to start a service.
# start_service "service_name" "message" "mode"
start_service() {
    local service_name="$1"
    local message="${2:-"Starting $service_name service..."}"

    # Default mode is system.
    local mode="${3:-system}"

    # Construct the systemctl command based on the mode.
    local systemctl_command="sudo systemctl"
    [ "$mode" = "user" ] && systemctl_command="systemctl --user"

    # Check if the service is already active.
    is_service_already_active=$(is_service_active "$service_name" "$mode")
    if [ "$is_service_already_active" = "false" ]; then
        log_info "$message"
        $systemctl_command start "$service_name"
    fi
}

# Function to stop a service.
# stop_service "service_name" "message" "mode"
stop_service() {
    local service_name="$1"
    local message="${2:-"Stoping $service_name service..."}"

    # Default mode is system.
    local mode="${3:-system}"

    # Construct the systemctl command based on the mode.
    local systemctl_command="sudo systemctl"
    [ "$mode" = "user" ] && systemctl_command="systemctl --user"

    # Check if the service is already active.
    is_service_already_active=$(is_service_active "$service_name" "$mode")
    if [ "$is_service_already_active" = "true" ]; then
        log_info "$message"
        $systemctl_command stop "$service_name"
    fi
}

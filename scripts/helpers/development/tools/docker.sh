#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DOCKER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DOCKER_SCRIPT_DIRECTORY/../../functions/services.sh"
source "$DOCKER_SCRIPT_DIRECTORY/../../functions/filesystem.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.
# ? Importing logs.sh is not needed, because it is already sourced in the other function scripts.

# Constant variables for the paths needed for configuring Docker.
DOCKER_DIRECTORY="/etc/docker"
DOCKER_LOGS="/var/lib/docker/containers/*/*-json.log"
DOCKER_DAEMON_CONFIGURATION="/etc/docker/daemon.json"
DOCKER_DAEMON_CONFIGURATION_TO_PASS="$DOCKER_SCRIPT_DIRECTORY/../../../configurations/information/neofetch.conf"

# Stop Docker service.
stop_service "docker"

# Truncate existing Docker logs if they exist.
for log_file in $DOCKER_LOGS; do
    if [ -f "$log_file" ]; then
        sudo truncate -s 0 "$log_file"
    fi
done

# Update the Docker daemon configuration.
# ? Use the JSON file log driver for Docker and update the log options.
# ? Set the maximum size of each log file to 10Mb.
# ? Set the maximum number of log files to retain to 3.
are_docker_daemon_files_the_same=$(compare_files "$DOCKER_DAEMON_CONFIGURATION" "$DOCKER_DAEMON_CONFIGURATION_TO_PASS")
if [ "$are_docker_daemon_files_the_same" = "false" ]; then
    log_info "Configuring Docker..."
    sudo mkdir -p "$DOCKER_DIRECTORY"
    cp -f "$DOCKER_DAEMON_CONFIGURATION_TO_PASS" "$DOCKER_DAEMON_CONFIGURATION"
fi

# Start Docker service.
start_service "docker"

# Enable Docker service.
enable_service "docker"

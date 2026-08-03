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
source "$DOCKER_SCRIPT_DIRECTORY/../../functions/packages.sh"
source "$DOCKER_SCRIPT_DIRECTORY/../../functions/system.sh"

# Constant variables for the paths needed for configuring Docker.
DOCKER_DIRECTORY="/etc/docker"
DOCKER_LOGS="/var/lib/docker/containers/*/*-json.log"
DOCKER_DAEMON_CONFIGURATION="/etc/docker/daemon.json"
DOCKER_DAEMON_CONFIGURATION_TO_PASS="$DOCKER_SCRIPT_DIRECTORY/../../configurations/security/docker/daemon.json"

# Initialize changes made flag.
docker_changes_made=1

# Install Docker packages.
log_info "Installing Docker packages..."
install_packages "$DOCKER_SCRIPT_DIRECTORY/../../packages/security/docker.txt" "$AUR_PACKAGE_MANAGER" "Installing Docker packages..."

# Configure subordinate uid/gid ranges for user namespace remapping.
# Check if dockremap user exists.
if ! id dockremap &>/dev/null; then
    log_info "Creating dockremap user for user namespace remapping..."
    sudo useradd -r dockremap
    docker_changes_made=0
fi

# Ensure /etc/subuid contains entry for dockremap.
if ! grep -q "^dockremap:" /etc/subuid; then
    # Get dockremap user's uid.
    dockremap_uid=$(id -u dockremap)
    log_info "Adding subordinate uid range for dockremap..."
    echo "dockremap:$dockremap_uid:65536" | sudo tee -a /etc/subuid >/dev/null
    docker_changes_made=0
fi

# Ensure /etc/subgid contains entry for dockremap.
if ! grep -q "^dockremap:" /etc/subgid; then
    # Get dockremap user's gid.
    dockremap_gid=$(id -g dockremap)
    log_info "Adding subordinate gid range for dockremap..."
    echo "dockremap:$dockremap_gid:65536" | sudo tee -a /etc/subgid >/dev/null
    docker_changes_made=0
fi

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
# ? Validate the JSON configuration.
log_info "Validating Docker configuration..."
if python3 -m json.tool "$DOCKER_DAEMON_CONFIGURATION_TO_PASS" > /dev/null; then
    log_info "Docker configuration is valid."
else
    log_error "Docker configuration is invalid."
    exit 1
fi

are_docker_daemon_files_the_same=$(compare_files "$DOCKER_DAEMON_CONFIGURATION" "$DOCKER_DAEMON_CONFIGURATION_TO_PASS")
if [ "$are_docker_daemon_files_the_same" = "false" ]; then
    log_info "Configuring Docker..."
    sudo mkdir -p "$DOCKER_DIRECTORY"
    sudo cp -f "$DOCKER_DAEMON_CONFIGURATION_TO_PASS" "$DOCKER_DAEMON_CONFIGURATION"
    docker_changes_made=0
fi

# Only restart Docker if changes were made.
if [ "$docker_changes_made" -eq 0 ]; then
    # Start Docker service.
    start_service "docker"
    # Enable Docker service.
    enable_service "docker"
fi

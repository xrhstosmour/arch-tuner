#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
REDIS_HELPER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$REDIS_HELPER_SCRIPT_DIRECTORY/../functions/containers.sh"

# Constant variable for the checked-out service directory.
REDIS_SERVICE_DIRECTORY="$CONTAINERS_DIRECTORY/databases/redis"

# Known, non-secret values. "REDIS_MAXIMUM_MEMORY" stays below the
# container's own 512M cgroup limit (docker-compose.yml's deploy.resources),
# so Redis evicts keys under its own policy before the container is OOM
# killed by the cgroup limit instead. The generated "REDIS_PASSWORD" is
# hexadecimal only, deliberately avoiding special characters per this
# template's own comment about client compatibility.
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -A redis_known_values=(
    ["COMPOSE_PROJECT_NAME"]="redis"
    ["REDIS_PORT"]="6379"
    ["REDIS_AOF_REWRITE_PERCENTAGE"]="100"
    ["REDIS_MAXIMUM_CLIENTS"]="10000"
    ["REDIS_AOF_REWRITE_MINIMUM_SIZE"]="64mb"
    ["REDIS_MAXIMUM_MEMORY"]="384mb"
)
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -a redis_secret_keys=("REDIS_PASSWORD")

log_info "Configuring Redis..."
render_environment_file "$REDIS_SERVICE_DIRECTORY/template.env" "$REDIS_SERVICE_DIRECTORY/.env" redis_known_values redis_secret_keys

log_info "Starting Redis..."
validate_container_service_configuration "$REDIS_SERVICE_DIRECTORY"
start_container_service "$REDIS_SERVICE_DIRECTORY"

log_success "Redis is running!"

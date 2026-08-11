#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
POSTGRESQL_HELPER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$POSTGRESQL_HELPER_SCRIPT_DIRECTORY/../functions/containers.sh"

# Constant variable for the checked-out service directory.
POSTGRESQL_SERVICE_DIRECTORY="$CONTAINERS_DIRECTORY/databases/postgresql"

# Known, non-secret values. "POSTGRESQL_HOST" is not read by the compose
# file itself, it documents the internal network hostname (the Docker
# Compose service name) for future consumer services' own ".env" files.
# "POSTGRESQL_ADDITIONAL_DATABASES" stays empty here, a consumer service
# such as Authelia or NetBird provisions its own database when it is added.
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -A postgresql_known_values=(
    ["COMPOSE_PROJECT_NAME"]="postgresql"
    ["POSTGRESQL_HOST"]="postgresql"
    ["POSTGRESQL_PORT"]="5432"
    ["POSTGRESQL_USER"]="arch_tuner"
    ["POSTGRESQL_AUTHENTICATION_METHOD"]="scram-sha-256"
    ["POSTGRESQL_ADDITIONAL_DATABASES"]=""
)
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -a postgresql_secret_keys=("POSTGRESQL_PASSWORD")

log_info "Configuring PostgreSQL..."
render_environment_file "$POSTGRESQL_SERVICE_DIRECTORY/template.env" "$POSTGRESQL_SERVICE_DIRECTORY/.env" postgresql_known_values postgresql_secret_keys

log_info "Starting PostgreSQL..."
validate_container_service_configuration "$POSTGRESQL_SERVICE_DIRECTORY"
start_container_service "$POSTGRESQL_SERVICE_DIRECTORY"

log_success "PostgreSQL is running!"

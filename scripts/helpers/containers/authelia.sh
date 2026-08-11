#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
AUTHELIA_HELPER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$AUTHELIA_HELPER_SCRIPT_DIRECTORY/../functions/containers.sh"
source "$AUTHELIA_HELPER_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variables for the checked-out service directory, this helper's
# own configuration payload, and the dependencies it reads credentials from.
AUTHELIA_SERVICE_DIRECTORY="$CONTAINERS_DIRECTORY/security/access/authelia"
AUTHELIA_OVERRIDE_SOURCE="$AUTHELIA_HELPER_SCRIPT_DIRECTORY/../../configurations/containers/authelia/docker-compose.override.yml"
AUTHELIA_OVERRIDE_TARGET="$AUTHELIA_SERVICE_DIRECTORY/docker-compose.override.yml"
POSTGRESQL_ENVIRONMENT_FILE="$CONTAINERS_DIRECTORY/databases/postgresql/.env"
REDIS_ENVIRONMENT_FILE="$CONTAINERS_DIRECTORY/databases/redis/.env"

postgresql_user=$(read_environment_value "$POSTGRESQL_ENVIRONMENT_FILE" "POSTGRESQL_USER")
postgresql_password=$(read_environment_value "$POSTGRESQL_ENVIRONMENT_FILE" "POSTGRESQL_PASSWORD")
postgresql_port=$(read_environment_value "$POSTGRESQL_ENVIRONMENT_FILE" "POSTGRESQL_PORT")
redis_password=$(read_environment_value "$REDIS_ENVIRONMENT_FILE" "REDIS_PASSWORD")
redis_port=$(read_environment_value "$REDIS_ENVIRONMENT_FILE" "REDIS_PORT")

log_info "Ensuring the 'authelia' database exists..."
ensure_postgresql_database "authelia" "$postgresql_user"

domain=$(get_containers_domain)
timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
admin_username=$(get_containers_admin_username)
admin_email=$(get_containers_admin_email)
admin_password=$(get_containers_admin_password)

# Known, non-secret values. The 3 "AUTHELIA_*" secrets below are generated,
# never prompted for, per this template's own comment to generate each with
# "openssl rand -hex 32", which is exactly what "generate_secret" does.
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -A authelia_known_values=(
    ["COMPOSE_PROJECT_NAME"]="authelia"
    ["TIMEZONE"]="$timezone"
    ["POSTGRESQL_PORT"]="$postgresql_port"
    ["POSTGRESQL_USER"]="$postgresql_user"
    ["POSTGRESQL_PASSWORD"]="$postgresql_password"
    ["REDIS_PORT"]="$redis_port"
    ["REDIS_PASSWORD"]="$redis_password"
    ["AUTHELIA_PORT"]="9091"
    ["DOMAIN"]="$domain"
    ["ADMIN_USERNAME"]="$admin_username"
    ["ADMIN_PASSWORD"]="$admin_password"
    ["ADMIN_EMAIL"]="$admin_email"
)
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -a authelia_secret_keys=("AUTHELIA_JWT_SECRET" "AUTHELIA_SESSION_SECRET" "AUTHELIA_STORAGE_ENCRYPTION_KEY")

log_info "Configuring Authelia..."
render_environment_file "$AUTHELIA_SERVICE_DIRECTORY/template.env" "$AUTHELIA_SERVICE_DIRECTORY/.env" authelia_known_values authelia_secret_keys

# The override below mounts "configuration/oidc-provider.yml" as a second
# "--config" path. A bind mount to a host path that does not exist yet gets
# silently created by Docker as an empty directory instead of a file,
# permanently breaking that mount for the container's lifetime. Ensure a
# minimal, valid placeholder is a real file before the override is ever
# applied, so this never happens on a first deploy, before NetBird's own
# helper has written the real OIDC provider configuration there.
AUTHELIA_OIDC_PROVIDER_FILE="$AUTHELIA_SERVICE_DIRECTORY/configuration/oidc-provider.yml"
if [ -d "$AUTHELIA_OIDC_PROVIDER_FILE" ]; then
    sudo rmdir "$AUTHELIA_OIDC_PROVIDER_FILE" 2>/dev/null || true
fi
if [ ! -f "$AUTHELIA_OIDC_PROVIDER_FILE" ]; then
    sudo mkdir -p "$(dirname "$AUTHELIA_OIDC_PROVIDER_FILE")"
    printf -- '---\n' | sudo tee "$AUTHELIA_OIDC_PROVIDER_FILE" >/dev/null
fi

# Front Authelia through Traefik instead of publishing its own host port.
sudo mkdir -p "$(dirname "$AUTHELIA_OVERRIDE_TARGET")"
if [ "$(compare_files "$AUTHELIA_OVERRIDE_TARGET" "$AUTHELIA_OVERRIDE_SOURCE")" == "false" ]; then
    sudo cp "$AUTHELIA_OVERRIDE_SOURCE" "$AUTHELIA_OVERRIDE_TARGET"
fi

log_info "Starting Authelia..."
validate_container_service_configuration "$AUTHELIA_SERVICE_DIRECTORY"
start_container_service "$AUTHELIA_SERVICE_DIRECTORY"

log_success "Authelia is running!"
log_success "Portal: https://authelia.$domain (username: $admin_username)"

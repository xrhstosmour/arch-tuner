#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
TRAEFIK_HELPER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$TRAEFIK_HELPER_SCRIPT_DIRECTORY/../functions/containers.sh"
source "$TRAEFIK_HELPER_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variables for the checked-out service directory and this helper's
# own configuration payload.
TRAEFIK_SERVICE_DIRECTORY="$CONTAINERS_DIRECTORY/networking/proxies/traefik"
TRAEFIK_OVERRIDE_SOURCE="$TRAEFIK_HELPER_SCRIPT_DIRECTORY/../../configurations/containers/traefik/docker-compose.override.yml"
TRAEFIK_OVERRIDE_TARGET="$TRAEFIK_SERVICE_DIRECTORY/docker-compose.override.yml"
TRAEFIK_HTPASSWD_FILE="$TRAEFIK_SERVICE_DIRECTORY/secrets/.htpasswd"

# The ACME HTTP-01 challenge needs 80 and 443 reachable, abort early with a
# clear reason instead of a Traefik startup failure the operator has to dig
# out of container logs.
for port in 80 443; do
    if [ "$(is_port_available "$port")" == "false" ]; then
        log_error "Port $port is already in use, Traefik needs both 80 and 443 free."
        exit 1
    fi
done

domain=$(get_containers_domain)
acme_email=$(get_acme_email)

# Known, non-secret values. "TIMEZONE" is auto-detected from the host, not
# prompted for.
timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -A traefik_known_values=(
    ["COMPOSE_PROJECT_NAME"]="traefik"
    ["TIMEZONE"]="$timezone"
    ["TRAEFIK_EMAIL"]="$acme_email"
    ["TRAEFIK_HOST"]="traefik.$domain"
    ["TRAEFIK_CERTIFICATE_RESOLVER"]="le"
)
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -a traefik_secret_keys=()

log_info "Configuring Traefik..."
render_environment_file "$TRAEFIK_SERVICE_DIRECTORY/template.env" "$TRAEFIK_SERVICE_DIRECTORY/.env" traefik_known_values traefik_secret_keys

# Copy the ACME-enabling override in place, only when it actually changed.
sudo mkdir -p "$(dirname "$TRAEFIK_OVERRIDE_TARGET")"
if [ "$(compare_files "$TRAEFIK_OVERRIDE_TARGET" "$TRAEFIK_OVERRIDE_SOURCE")" == "false" ]; then
    sudo cp "$TRAEFIK_OVERRIDE_SOURCE" "$TRAEFIK_OVERRIDE_TARGET"
fi

# Generate the dashboard credentials once, reusing the same password on
# every rerun instead of prompting for one.
dashboard_username="admin"
dashboard_password=$(get_or_generate_shared_secret "CONTAINERS_TRAEFIK_DASHBOARD_PASSWORD" 16)
if [ ! -f "$TRAEFIK_HTPASSWD_FILE" ]; then
    log_info "Generating Traefik dashboard credentials..."
    sudo mkdir -p "$(dirname "$TRAEFIK_HTPASSWD_FILE")"
    generate_htpasswd_entry "$dashboard_username" "$dashboard_password" | sudo tee "$TRAEFIK_HTPASSWD_FILE" >/dev/null
    sudo chmod 0600 "$TRAEFIK_HTPASSWD_FILE"
fi

log_info "Starting Traefik..."
validate_container_service_configuration "$TRAEFIK_SERVICE_DIRECTORY"
start_container_service "$TRAEFIK_SERVICE_DIRECTORY"

log_success "Traefik is running!"
log_success "Dashboard: https://traefik.$domain (username: $dashboard_username, password: $dashboard_password)"

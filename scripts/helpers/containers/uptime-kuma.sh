#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
UPTIME_KUMA_HELPER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$UPTIME_KUMA_HELPER_SCRIPT_DIRECTORY/../functions/containers.sh"
source "$UPTIME_KUMA_HELPER_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variable for the checked-out service directory.
UPTIME_KUMA_SERVICE_DIRECTORY="$CONTAINERS_DIRECTORY/monitoring/services/uptime-kuma"
UPTIME_KUMA_OVERRIDE_TARGET="$UPTIME_KUMA_SERVICE_DIRECTORY/docker-compose.override.yml"

domain=$(get_containers_domain)
uptime_kuma_domain="uptime.$domain"

# Its own "template.env" has no domain variable, the domain is rendered
# directly into a generated override instead of referenced as "${DOMAIN}",
# the same technique NetBird's helper uses for Authelia's OIDC provider.
override_temporary_file=$(mktemp)
cat >"$override_temporary_file" <<EOF
services:
  uptime-kuma:
    ports: !reset []
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=internal"
      - "traefik.http.routers.uptime-kuma.rule=Host(\`$uptime_kuma_domain\`)"
      - "traefik.http.routers.uptime-kuma.entrypoints=web_secure"
      - "traefik.http.routers.uptime-kuma.tls=true"
      - "traefik.http.routers.uptime-kuma.tls.options=tls-opts@file"
      - "traefik.http.routers.uptime-kuma.tls.certresolver=le"
EOF

sudo mkdir -p "$(dirname "$UPTIME_KUMA_OVERRIDE_TARGET")"
if [ "$(compare_files "$UPTIME_KUMA_OVERRIDE_TARGET" "$override_temporary_file")" == "false" ]; then
    sudo cp "$override_temporary_file" "$UPTIME_KUMA_OVERRIDE_TARGET"
fi
rm -f "$override_temporary_file"

# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -A uptime_kuma_known_values=(["COMPOSE_PROJECT_NAME"]="uptime-kuma")
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -a uptime_kuma_secret_keys=()

log_info "Configuring Uptime Kuma..."
render_environment_file "$UPTIME_KUMA_SERVICE_DIRECTORY/template.env" "$UPTIME_KUMA_SERVICE_DIRECTORY/.env" uptime_kuma_known_values uptime_kuma_secret_keys

log_info "Starting Uptime Kuma..."
validate_container_service_configuration "$UPTIME_KUMA_SERVICE_DIRECTORY"
start_container_service "$UPTIME_KUMA_SERVICE_DIRECTORY"

log_success "Uptime Kuma is running!"
log_success "https://$uptime_kuma_domain (create the admin account on first visit)"

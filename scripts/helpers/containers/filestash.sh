#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
FILESTASH_HELPER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$FILESTASH_HELPER_SCRIPT_DIRECTORY/../functions/containers.sh"
source "$FILESTASH_HELPER_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variable for the checked-out service directory.
FILESTASH_SERVICE_DIRECTORY="$CONTAINERS_DIRECTORY/storage/filestash"
FILESTASH_OVERRIDE_TARGET="$FILESTASH_SERVICE_DIRECTORY/docker-compose.override.yml"

domain=$(get_containers_domain)
filestash_domain="filestash.$domain"

# Filestash's own "template.env" has no domain variable, unlike Traefik's
# or Authelia's, so this override cannot reference "${DOMAIN}" the same
# way, it renders the chosen domain directly into a generated file instead,
# the same technique NetBird's helper uses for Authelia's OIDC provider.
override_temporary_file=$(mktemp)
cat >"$override_temporary_file" <<EOF
services:
  filestash:
    ports: !reset []
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=internal"
      - "traefik.http.routers.filestash.rule=Host(\`$filestash_domain\`)"
      - "traefik.http.routers.filestash.entrypoints=web_secure"
      - "traefik.http.routers.filestash.tls=true"
      - "traefik.http.routers.filestash.tls.options=tls-opts@file"
      - "traefik.http.routers.filestash.tls.certresolver=le"
EOF

sudo mkdir -p "$(dirname "$FILESTASH_OVERRIDE_TARGET")"
if [ "$(compare_files "$FILESTASH_OVERRIDE_TARGET" "$override_temporary_file")" == "false" ]; then
    sudo cp "$override_temporary_file" "$FILESTASH_OVERRIDE_TARGET"
fi
rm -f "$override_temporary_file"

# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -A filestash_known_values=(
    ["COMPOSE_PROJECT_NAME"]="filestash"
    ["FILESTASH_APPLICATION_URL"]="https://$filestash_domain"
)
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -a filestash_secret_keys=()

log_info "Configuring Filestash..."
render_environment_file "$FILESTASH_SERVICE_DIRECTORY/template.env" "$FILESTASH_SERVICE_DIRECTORY/.env" filestash_known_values filestash_secret_keys

log_info "Starting Filestash..."
validate_container_service_configuration "$FILESTASH_SERVICE_DIRECTORY"
start_container_service "$FILESTASH_SERVICE_DIRECTORY"

log_success "Filestash is running!"
log_success "https://$filestash_domain (set the admin password on first visit, at /admin)"

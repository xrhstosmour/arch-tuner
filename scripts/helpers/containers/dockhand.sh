#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DOCKHAND_HELPER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DOCKHAND_HELPER_SCRIPT_DIRECTORY/../functions/containers.sh"
source "$DOCKHAND_HELPER_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variable for the checked-out service directory.
DOCKHAND_SERVICE_DIRECTORY="$CONTAINERS_DIRECTORY/management/services/dockhand"
DOCKHAND_OVERRIDE_TARGET="$DOCKHAND_SERVICE_DIRECTORY/docker-compose.override.yml"

domain=$(get_containers_domain)
dockhand_domain="dockhand.$domain"

# Its own "template.env" has no domain variable, the domain is rendered
# directly into a generated override instead of referenced as "${DOMAIN}".
override_temporary_file=$(mktemp)
cat >"$override_temporary_file" <<EOF
services:
  dockhand:
    ports: !reset []
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=internal"
      - "traefik.http.routers.dockhand.rule=Host(\`$dockhand_domain\`)"
      - "traefik.http.routers.dockhand.entrypoints=web_secure"
      - "traefik.http.routers.dockhand.tls=true"
      - "traefik.http.routers.dockhand.tls.options=tls-opts@file"
      - "traefik.http.routers.dockhand.tls.certresolver=le"
EOF

sudo mkdir -p "$(dirname "$DOCKHAND_OVERRIDE_TARGET")"
if [ "$(compare_files "$DOCKHAND_OVERRIDE_TARGET" "$override_temporary_file")" == "false" ]; then
    sudo cp "$override_temporary_file" "$DOCKHAND_OVERRIDE_TARGET"
fi
rm -f "$override_temporary_file"

# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -A dockhand_known_values=(["COMPOSE_PROJECT_NAME"]="dockhand")
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -a dockhand_secret_keys=()

log_info "Configuring Dockhand..."
render_environment_file "$DOCKHAND_SERVICE_DIRECTORY/template.env" "$DOCKHAND_SERVICE_DIRECTORY/.env" dockhand_known_values dockhand_secret_keys

log_info "Starting Dockhand..."
validate_container_service_configuration "$DOCKHAND_SERVICE_DIRECTORY"
start_container_service "$DOCKHAND_SERVICE_DIRECTORY"

log_success "Dockhand is running!"
log_success "https://$dockhand_domain (create the admin account on first visit)"
log_success "Add a Docker environment in Settings > Environments pointing at tcp://docker-socket-proxy:2375"

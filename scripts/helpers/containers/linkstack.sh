#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
LINKSTACK_HELPER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$LINKSTACK_HELPER_SCRIPT_DIRECTORY/../functions/containers.sh"
source "$LINKSTACK_HELPER_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variable for the checked-out service directory.
LINKSTACK_SERVICE_DIRECTORY="$CONTAINERS_DIRECTORY/web/sharing/linkstack"
LINKSTACK_OVERRIDE_TARGET="$LINKSTACK_SERVICE_DIRECTORY/docker-compose.override.yml"

domain=$(get_containers_domain)
admin_email=$(get_containers_admin_email)
linkstack_domain="linkstack.$domain"

# Its own "template.env" has no domain variable, the domain is rendered
# directly into a generated override instead of referenced as "${DOMAIN}".
# The container exposes both 80 and 443 itself, unlike Filestash/Uptime
# Kuma's single port, so Traefik needs an explicit service port, it cannot
# guess which of the two to route to.
override_temporary_file=$(mktemp)
cat >"$override_temporary_file" <<EOF
services:
  linkstack:
    ports: !reset []
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=internal"
      - "traefik.http.services.linkstack.loadbalancer.server.port=80"
      - "traefik.http.routers.linkstack.rule=Host(\`$linkstack_domain\`)"
      - "traefik.http.routers.linkstack.entrypoints=web_secure"
      - "traefik.http.routers.linkstack.tls=true"
      - "traefik.http.routers.linkstack.tls.options=tls-opts@file"
      - "traefik.http.routers.linkstack.tls.certresolver=le"
EOF

sudo mkdir -p "$(dirname "$LINKSTACK_OVERRIDE_TARGET")"
if [ "$(compare_files "$LINKSTACK_OVERRIDE_TARGET" "$override_temporary_file")" == "false" ]; then
    sudo cp "$override_temporary_file" "$LINKSTACK_OVERRIDE_TARGET"
fi
rm -f "$override_temporary_file"

timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -A linkstack_known_values=(
    ["COMPOSE_PROJECT_NAME"]="linkstack"
    ["TIMEZONE"]="$timezone"
    ["LINKSTACK_SERVER_ADMIN"]="$admin_email"
    ["LINKSTACK_HTTP_SERVER_NAME"]="$linkstack_domain"
    ["LINKSTACK_HTTPS_SERVER_NAME"]="$linkstack_domain"
    ["LINKSTACK_LOG_LEVEL"]="info"
    ["LINKSTACK_PHP_MEMORY_LIMIT"]="256M"
    ["LINKSTACK_UPLOAD_MAX_FILESIZE"]="8M"
)
# shellcheck disable=SC2034 # Reason: nameref, read by render_environment_file by name, not read here.
declare -a linkstack_secret_keys=()

log_info "Configuring LinkStack..."
render_environment_file "$LINKSTACK_SERVICE_DIRECTORY/template.env" "$LINKSTACK_SERVICE_DIRECTORY/.env" linkstack_known_values linkstack_secret_keys

log_info "Starting LinkStack..."
validate_container_service_configuration "$LINKSTACK_SERVICE_DIRECTORY"
start_container_service "$LINKSTACK_SERVICE_DIRECTORY"

log_success "LinkStack is running!"
log_success "https://$linkstack_domain (create the admin account on first visit)"

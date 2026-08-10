#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
CONTAINERS_FUNCTIONS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$CONTAINERS_FUNCTIONS_SCRIPT_DIRECTORY/logs.sh"
source "$CONTAINERS_FUNCTIONS_SCRIPT_DIRECTORY/state.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

# Function to run the Docker Compose CLI, preferring the "docker compose"
# plugin subcommand and falling back to the standalone "docker-compose"
# binary when the plugin is unavailable.
# Usage:
#   docker_compose "up" "-d"
docker_compose() {
    if docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

# Function to clone the pinned containers repository if it is missing, or
# fetch and check out the pinned commit if it already exists, so every
# helper works against the exact same, reviewed revision.
# Usage:
#   checkout_containers_repository
checkout_containers_repository() {
    if [ ! -d "$CONTAINERS_DIRECTORY/.git" ]; then
        log_info "Cloning containers repository..."
        sudo mkdir -p "$(dirname "$CONTAINERS_DIRECTORY")"
        sudo git clone "$CONTAINERS_REPOSITORY_URL" "$CONTAINERS_DIRECTORY"
    fi

    local current_commit
    current_commit=$(sudo git -C "$CONTAINERS_DIRECTORY" rev-parse HEAD)
    if [ "$current_commit" != "$CONTAINERS_REPOSITORY_COMMIT" ]; then
        log_info "Checking out pinned containers repository commit..."
        sudo git -C "$CONTAINERS_DIRECTORY" fetch --quiet origin "$CONTAINERS_REPOSITORY_COMMIT"
        sudo git -C "$CONTAINERS_DIRECTORY" checkout --quiet "$CONTAINERS_REPOSITORY_COMMIT"
    fi
}

# Function to create the shared external Docker network every container
# stack attaches to, if it does not already exist.
# Usage:
#   ensure_containers_network
ensure_containers_network() {
    if ! sudo docker network inspect "$CONTAINERS_NETWORK_NAME" >/dev/null 2>&1; then
        log_info "Creating '$CONTAINERS_NETWORK_NAME' Docker network..."
        sudo docker network create "$CONTAINERS_NETWORK_NAME" >/dev/null
    fi
}

# Function to generate a random secret.
# Usage:
#   generate_secret "32"
generate_secret() {
    local length="${1:-32}"
    openssl rand -hex "$length"
}

# Function to return an already-generated secret from the state file, or
# generate and persist one if it does not exist yet, so every helper that
# needs the same secret across separate runs, or separate stacks sharing one
# dependency such as a database password, gets back the same value.
# Usage:
#   get_or_generate_shared_secret "flag_name" "length"
get_or_generate_shared_secret() {
    local flag_name="$1"
    local length="${2:-32}"

    source_state

    if [ -n "${!flag_name}" ]; then
        echo "${!flag_name}"
        return
    fi

    local secret
    secret=$(generate_secret "$length")
    change_flag_value "$flag_name" "$secret"
    echo "$secret"
}

# Function to check whether a TCP port is free on the host.
# Usage:
#   is_port_available "8080"
is_port_available() {
    local port="$1"

    if sudo ss -tln | awk '{print $4}' | grep -qE "[.:]${port}\$"; then
        echo "false"
    else
        echo "true"
    fi
}

# Function to render an environment file from a "template.env"-style file.
# For every "KEY=VALUE" line in the template: a key already present in the
# target file keeps its existing value untouched, so a rerun never
# regenerates a secret or forgets a value the operator or a previous render
# already set. Otherwise, a key present in the "known_values" associative
# array (by name) uses that value, a key present in the "secret_keys"
# indexed array (by name) gets a generated secret, and any other key falls
# through to the template's own placeholder, unchanged. Callers are
# responsible for covering every required variable via one of these two
# arrays, anything left as a template placeholder is not a working value.
# Usage:
#   render_environment_file "template.env" ".env" known_values_array_name secret_keys_array_name
render_environment_file() {
    local template_file="$1"
    local target_file="$2"
    local -n known_values_ref="$3"
    local -n secret_keys_ref="$4"

    local -A existing_values=()
    if [ -f "$target_file" ]; then
        while IFS='=' read -r existing_key existing_value; do
            [[ -z "$existing_key" || "$existing_key" == \#* ]] && continue
            existing_values["$existing_key"]="$existing_value"
        done <"$target_file"
    fi

    local temp_file
    temp_file=$(mktemp)

    local line key value
    while IFS= read -r line; do
        if [[ -z "$line" || "$line" == \#* || "$line" != *=* ]]; then
            echo "$line" >>"$temp_file"
            continue
        fi

        key="${line%%=*}"
        value="${line#*=}"

        if [ -n "${existing_values[$key]+x}" ]; then
            value="${existing_values[$key]}"
        elif [ -n "${known_values_ref[$key]+x}" ]; then
            value="${known_values_ref[$key]}"
        else
            for secret_key in "${secret_keys_ref[@]}"; do
                if [ "$secret_key" == "$key" ]; then
                    value=$(generate_secret 32)
                    break
                fi
            done
        fi

        echo "$key=$value" >>"$temp_file"
    done <"$template_file"

    sudo mkdir -p "$(dirname "$target_file")"
    sudo cp "$temp_file" "$target_file"
    sudo chmod 0600 "$target_file"
    rm -f "$temp_file"
}

# Function to generate a bcrypt htpasswd entry for HTTP basic authentication,
# without requiring an "apache-utils"/"httpd-tools" package on the host.
# Usage:
#   generate_htpasswd_entry "username" "password"
generate_htpasswd_entry() {
    local username="$1"
    local password="$2"

    sudo docker run --rm httpd:alpine htpasswd -Bbn "$username" "$password"
}

# Function to validate a service's Docker Compose configuration.
# Usage:
#   validate_container_service_configuration "/path/to/service/directory"
validate_container_service_configuration() {
    local service_directory="$1"

    (cd "$service_directory" && docker_compose config >/dev/null)
}

# Function to bring up a service's Docker Compose stack.
# Usage:
#   start_container_service "/path/to/service/directory"
start_container_service() {
    local service_directory="$1"

    (cd "$service_directory" && docker_compose up -d)
}

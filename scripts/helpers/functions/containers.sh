#!/bin/bash

# Constant variable of the scripts' working directory to use for relative paths.
CONTAINERS_FUNCTIONS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$CONTAINERS_FUNCTIONS_SCRIPT_DIRECTORY/logs.sh"
source "$CONTAINERS_FUNCTIONS_SCRIPT_DIRECTORY/state.sh"
source "$CONTAINERS_FUNCTIONS_SCRIPT_DIRECTORY/ui.sh"

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
        local existing_line existing_key existing_value
        while IFS= read -r existing_line; do
            [[ -z "$existing_line" || "$existing_line" == \#* || "$existing_line" != *=* ]] && continue
            # Parameter expansion, not "IFS='=' read", "read" silently
            # drops a trailing delimiter with nothing after it, corrupting
            # any value ending in "=", such as base64 padding, verified
            # against a real value one byte at a time until this surfaced.
            existing_key="${existing_line%%=*}"
            existing_value="${existing_line#*=}"
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

# Function to prompt for the domain pointed at this server, once, and
# persist the choice so later container helpers, such as an Authelia or
# NetBird subdomain, reuse the exact same value.
# Usage:
#   get_containers_domain
get_containers_domain() {
    source_state

    if [ -n "$CONTAINERS_DOMAIN" ]; then
        echo "$CONTAINERS_DOMAIN"
        return
    fi

    local domain=""
    while :; do
        domain=$(prompt_user_input "Enter the domain pointed at this server" "")

        if [[ "$domain" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
            break
        fi

        log_error "Invalid domain: '$domain'."
    done

    change_flag_value "CONTAINERS_DOMAIN" "$domain"
    echo "$domain"
}

# Function to prompt for the email address used for ACME (Let's Encrypt)
# certificate registration, once, and persist the choice.
# Usage:
#   get_acme_email
get_acme_email() {
    source_state

    if [ -n "$CONTAINERS_ACME_EMAIL" ]; then
        echo "$CONTAINERS_ACME_EMAIL"
        return
    fi

    local email=""
    while :; do
        email=$(prompt_user_input "Enter the email address for Let's Encrypt ACME registration" "")

        if [[ "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
            break
        fi

        log_error "Invalid email address: '$email'."
    done

    change_flag_value "CONTAINERS_ACME_EMAIL" "$email"
    echo "$email"
}

# Function to prompt for a value without echoing it to the terminal, for
# credentials such as an admin password.
# Usage:
#   prompt_hidden_input "prompt_message"
prompt_hidden_input() {
    local prompt="$1"
    local input=""

    log_info -n "$prompt: "
    read -rs input
    echo >&2

    echo "$input"
}

# Function to prompt for the admin username, once, and persist the choice.
# Usage:
#   get_containers_admin_username
get_containers_admin_username() {
    source_state

    if [ -n "$CONTAINERS_ADMIN_USERNAME" ]; then
        echo "$CONTAINERS_ADMIN_USERNAME"
        return
    fi

    local username=""
    while :; do
        username=$(prompt_user_input "Enter the admin username" "admin")

        if [[ "$username" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
            break
        fi

        log_error "Invalid username: '$username'."
    done

    change_flag_value "CONTAINERS_ADMIN_USERNAME" "$username"
    echo "$username"
}

# Function to prompt for the admin email address, once, and persist the
# choice. Kept separate from "get_acme_email", the two can differ.
# Usage:
#   get_containers_admin_email
get_containers_admin_email() {
    source_state

    if [ -n "$CONTAINERS_ADMIN_EMAIL" ]; then
        echo "$CONTAINERS_ADMIN_EMAIL"
        return
    fi

    local email=""
    while :; do
        email=$(prompt_user_input "Enter the admin email address" "")

        if [[ "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
            break
        fi

        log_error "Invalid email address: '$email'."
    done

    change_flag_value "CONTAINERS_ADMIN_EMAIL" "$email"
    echo "$email"
}

# Function to prompt for the admin password, once, with confirmation, and
# persist the choice. Rejects "$" and a backtick, "change_flag_value"
# rejects those too, to keep the state file, sourced as executable bash on
# every run, safe from injection.
# Usage:
#   get_containers_admin_password
get_containers_admin_password() {
    source_state

    if [ -n "$CONTAINERS_ADMIN_PASSWORD" ]; then
        echo "$CONTAINERS_ADMIN_PASSWORD"
        return
    fi

    local password="" confirmation=""
    while :; do
        password=$(prompt_hidden_input "Enter the admin password, at least 12 characters, no '\$' or backtick")

        if [[ "$password" == *'$'* || "$password" == *'`'* ]]; then
            log_error "Password cannot contain '\$' or a backtick."
            continue
        fi

        if [ "${#password}" -lt 12 ]; then
            log_error "Password must be at least 12 characters."
            continue
        fi

        confirmation=$(prompt_hidden_input "Confirm the admin password")

        if [ "$password" == "$confirmation" ]; then
            break
        fi

        log_error "Passwords did not match."
    done

    change_flag_value "CONTAINERS_ADMIN_PASSWORD" "$password"
    echo "$password"
}

# Function to read a single value out of an already-rendered ".env" file, so
# a consumer service can reuse a dependency's generated credentials, such as
# the shared PostgreSQL or Redis password, without duplicating them into
# arch-tuner's own state file.
# Usage:
#   read_environment_value "/path/to/.env" "KEY"
read_environment_value() {
    local target_file="$1"
    local key="$2"

    sudo grep -m 1 "^${key}=" "$target_file" | cut -d '=' -f 2-
}

# Function to ensure a database exists on the shared PostgreSQL container,
# for a consumer added after PostgreSQL was already initialized. The
# upstream image's own additional-databases mechanism only runs once, on
# first initialization of an empty data directory, it does not retroactively
# create a database added to "POSTGRESQL_ADDITIONAL_DATABASES" afterward.
# Usage:
#   ensure_postgresql_database "database_name" "owner"
ensure_postgresql_database() {
    local database_name="$1"
    local owner="$2"

    # "\gexec" is a psql client-side meta-command, it only works fed through
    # stdin (matching the upstream image's own "initialize-databases.sh"),
    # not passed as a "-c" argument string.
    sudo docker exec -i postgresql psql -v ON_ERROR_STOP=1 --username "$owner" >/dev/null <<EOSQL
SELECT 'CREATE DATABASE "${database_name}"'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = '${database_name}'
)\gexec
EOSQL
}

# Function to generate an RSA private key in PKCS#8 PEM format, for a
# service that needs to sign tokens with its own key, such as an OIDC
# provider's JSON Web Key Set.
# Usage:
#   generate_rsa_private_key
generate_rsa_private_key() {
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 2>/dev/null
}

# Function to return an already-generated file's content, or generate and
# persist one if the file does not exist yet, for a value too large or
# unsafe for the single-line state file, such as a multi-line PEM key.
# Usage:
#   get_or_generate_file_secret "/path/to/file" "generator_function_name"
get_or_generate_file_secret() {
    local target_file="$1"
    local generator_function_name="$2"

    if [ ! -f "$target_file" ]; then
        sudo mkdir -p "$(dirname "$target_file")"
        "$generator_function_name" | sudo tee "$target_file" >/dev/null
        sudo chmod 0600 "$target_file"
    fi

    sudo cat "$target_file"
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

# Function to force a service's Docker Compose stack to recreate. Compose
# only detects a change from the resolved compose configuration itself
# (image, environment, command, labels, ...), never from the contents of a
# file it bind-mounts, so a rerun that only changes such a file's content,
# without changing the mount's declared path, needs this instead of
# "start_container_service", verified against a real Docker Compose run.
# Usage:
#   force_recreate_container_service "/path/to/service/directory"
force_recreate_container_service() {
    local service_directory="$1"

    (cd "$service_directory" && docker_compose up -d --force-recreate)
}

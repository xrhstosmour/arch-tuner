#!/usr/bin/env bats

setup() {
    authelia_script="$BATS_TEST_DIRNAME/../scripts/helpers/containers/authelia.sh"
    override_file="$BATS_TEST_DIRNAME/../scripts/configurations/containers/authelia/docker-compose.override.yml"
}

@test "authelia.sh generates the 3 Authelia secrets instead of hardcoding them" {
    for key in AUTHELIA_JWT_SECRET AUTHELIA_SESSION_SECRET AUTHELIA_STORAGE_ENCRYPTION_KEY; do
        ! grep -q "known_values=.*$key" "$authelia_script"
    done
    grep -q 'secret_keys=("AUTHELIA_JWT_SECRET" "AUTHELIA_SESSION_SECRET" "AUTHELIA_STORAGE_ENCRYPTION_KEY")' "$authelia_script"
}

@test "authelia.sh reads the shared PostgreSQL and Redis credentials instead of generating its own" {
    grep -q 'read_environment_value "\$POSTGRESQL_ENVIRONMENT_FILE" "POSTGRESQL_PASSWORD"' "$authelia_script"
    grep -q 'read_environment_value "\$REDIS_ENVIRONMENT_FILE" "REDIS_PASSWORD"' "$authelia_script"
}

@test "authelia.sh ensures its own database exists before rendering configuration" {
    grep -q 'ensure_postgresql_database "authelia"' "$authelia_script"
}

@test "the override closes Authelia's own published port and fronts it through Traefik" {
    # A bare "ports: []" does not clear the base file's ports mapping in
    # Compose's merge library, "!reset" is required, see docker-compose.override.yml's own comment.
    grep -q 'ports: !reset \[\]' "$override_file"
    grep -q 'traefik.enable=true' "$override_file"
    grep -q 'authelia\.\${DOMAIN' "$override_file"
}

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

@test "the override loads oidc-provider.yml as a second Authelia config path, without dropping the base entrypoint script" {
    grep -q './configuration/oidc-provider.yml:/oidc-provider.yml:ro' "$override_file"
    grep -q -- '--config /tmp/configuration.yml --config /oidc-provider.yml' "$override_file"
    # The base script's Postgres/Redis wait loops and user database
    # rendering must survive the full command-list replacement.
    grep -q 'Waiting for PostgreSQL' "$override_file"
    grep -q 'users_database.yml' "$override_file"
}

@test "authelia.sh ensures oidc-provider.yml is a real file before applying the override that mounts it" {
    # Regression guard: a bind mount to a missing host path is silently
    # created by Docker as an empty directory instead of a file, verified
    # against a real Docker run, permanently breaking that mount. This
    # placeholder step must run, and be ordered, before the override copy.
    placeholder_line=$(grep -n 'AUTHELIA_OIDC_PROVIDER_FILE' "$authelia_script" | head -1 | cut -d: -f1)
    override_copy_line=$(grep -n 'cp "\$AUTHELIA_OVERRIDE_SOURCE"' "$authelia_script" | head -1 | cut -d: -f1)

    [ -n "$placeholder_line" ]
    [ -n "$override_copy_line" ]
    [ "$placeholder_line" -lt "$override_copy_line" ]
    grep -q "if \[ -d \"\$AUTHELIA_OIDC_PROVIDER_FILE\" \]" "$authelia_script"
}

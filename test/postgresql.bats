#!/usr/bin/env bats

setup() {
    postgresql_script="$BATS_TEST_DIRNAME/../scripts/helpers/containers/postgresql.sh"
}

@test "postgresql.sh never uses the trust authentication method" {
    # Regression guard: "trust" allows unauthenticated connections
    # unconditionally, never a safe default even on an internal network.
    ! grep -q 'POSTGRESQL_AUTHENTICATION_METHOD.*=.*trust' "$postgresql_script"
    grep -q 'POSTGRESQL_AUTHENTICATION_METHOD.*=.*scram-sha-256' "$postgresql_script"
}

@test "postgresql.sh generates the database password instead of hardcoding it" {
    ! grep -q 'known_values=.*POSTGRESQL_PASSWORD' "$postgresql_script"
    grep -q 'secret_keys=("POSTGRESQL_PASSWORD")' "$postgresql_script"
}

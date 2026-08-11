#!/usr/bin/env bats

setup() {
    netbird_script="$BATS_TEST_DIRNAME/../scripts/helpers/containers/netbird.sh"
}

@test "netbird.sh checks every fixed TCP port before starting, coturn's UDP range excepted" {
    for port_name in NETBIRD_DASHBOARD_HTTP_PORT NETBIRD_DASHBOARD_HTTPS_PORT NETBIRD_SIGNAL_PORT NETBIRD_RELAY_PORT NETBIRD_MANAGEMENT_PORT; do
        grep -q "\"$port_name\"" "$netbird_script"
    done
    grep -q 'for port_name in "\${!netbird_ports\[@\]}"' "$netbird_script"
}

@test "netbird.sh generates the datastore encryption key as base64, not the usual hexadecimal secret" {
    # Regression guard: upstream's own template documents "openssl rand
    # -base64 32" specifically for this one key, unlike every other secret.
    grep -q 'openssl rand -base64 32' "$netbird_script"
    ! grep -q 'known_values=.*NETBIRD_DATASTORE_ENCRYPTION_KEY.*\$(generate_secret' "$netbird_script"
}

@test "netbird.sh never generates a client secret, NetBird is registered as a public OIDC client" {
    grep -q "client_secret: ''" "$netbird_script"
    grep -q "public: true" "$netbird_script"
    grep -q "token_endpoint_auth_method: 'none'" "$netbird_script"
}

@test "netbird.sh persists the OIDC signing key as a file, not the single-line state file" {
    grep -q 'get_or_generate_file_secret "\$AUTHELIA_OIDC_SIGNING_KEY_FILE" "generate_rsa_private_key"' "$netbird_script"
}

@test "netbird.sh reapplies authelia.sh after writing the OIDC provider file" {
    grep -q 'sh "\$NETBIRD_HELPER_SCRIPT_DIRECTORY/authelia.sh"' "$netbird_script"
}

@test "netbird.sh ensures its own database exists before rendering configuration" {
    grep -q 'ensure_postgresql_database "netbird"' "$netbird_script"
}

#!/usr/bin/env bats

setup() {
    containers_under_test="$BATS_TEST_DIRNAME/../scripts/helpers/functions/containers.sh"

    export ARCH_TUNER_STATE_DIRECTORY="$BATS_TEST_TMPDIR"

    sudo() { command "$@"; }
    export -f sudo

    fake_bin="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$fake_bin"
    calls_log="$BATS_TEST_TMPDIR/calls.log"
    : >"$calls_log"

    source "$containers_under_test"
}

@test "generate_secret returns a hexadecimal string of the requested byte length" {
    run generate_secret "16"

    [ "$status" -eq 0 ]
    [ "${#output}" -eq 32 ]
    [[ "$output" =~ ^[0-9a-f]+$ ]]
}

@test "generate_secret defaults to 32 bytes when no length is given" {
    run generate_secret

    [ "${#output}" -eq 64 ]
}

@test "get_or_generate_shared_secret generates and persists a secret on first call" {
    run get_or_generate_shared_secret "EXAMPLE_SECRET" "16"

    [ "$status" -eq 0 ]
    [ "${#output}" -eq 32 ]
    grep -q '^EXAMPLE_SECRET=' "$STATE_FILE"
}

@test "get_or_generate_shared_secret returns the same secret on a second call instead of regenerating" {
    first=$(get_or_generate_shared_secret "EXAMPLE_SECRET" "16")
    second=$(get_or_generate_shared_secret "EXAMPLE_SECRET" "16")

    [ "$first" = "$second" ]
}

@test "docker_compose prefers the docker compose plugin subcommand when available" {
    cat >"$fake_bin/docker" <<EOF
#!/usr/bin/env bash
echo "call: \$*" >> "$calls_log"
if [ "\$1" = "compose" ] && [ "\$2" = "version" ]; then
    exit 0
fi
EOF
    chmod +x "$fake_bin/docker"
    PATH="$fake_bin:$PATH"

    docker_compose "config"

    grep -qxF 'call: compose version' "$calls_log"
    grep -qxF 'call: compose config' "$calls_log"
}

@test "docker_compose falls back to the standalone docker-compose binary when the plugin is unavailable" {
    cat >"$fake_bin/docker" <<EOF
#!/usr/bin/env bash
echo "call: \$*" >> "$calls_log"
exit 1
EOF
    chmod +x "$fake_bin/docker"
    cat >"$fake_bin/docker-compose" <<EOF
#!/usr/bin/env bash
echo "fallback call: \$*" >> "$calls_log"
EOF
    chmod +x "$fake_bin/docker-compose"
    PATH="$fake_bin:$PATH"

    docker_compose "config"

    grep -qxF 'fallback call: config' "$calls_log"
}

@test "is_port_available reports true when ss shows no listener on the port" {
    cat >"$fake_bin/ss" <<'EOF'
#!/usr/bin/env bash
printf 'State  Recv-Q Send-Q Local Address:Port  Peer Address:Port\n'
printf 'LISTEN 0      128    0.0.0.0:22           0.0.0.0:*\n'
EOF
    chmod +x "$fake_bin/ss"
    PATH="$fake_bin:$PATH"

    run is_port_available "443"

    [ "$output" = "true" ]
}

@test "is_port_available reports false when ss shows a listener on the port" {
    cat >"$fake_bin/ss" <<'EOF'
#!/usr/bin/env bash
printf 'State  Recv-Q Send-Q Local Address:Port  Peer Address:Port\n'
printf 'LISTEN 0      128    0.0.0.0:443          0.0.0.0:*\n'
printf 'LISTEN 0      128    [::]:443             [::]:*\n'
EOF
    chmod +x "$fake_bin/ss"
    PATH="$fake_bin:$PATH"

    run is_port_available "443"

    [ "$output" = "false" ]
}

@test "render_environment_file fills known values and generates secrets for a fresh target" {
    template="$BATS_TEST_TMPDIR/template.env"
    target="$BATS_TEST_TMPDIR/rendered.env"
    cat >"$template" <<'EOF'
# A comment line.
COMPOSE_PROJECT_NAME='lowercase_string_without_special_characters'
DOMAIN='string_with_special_characters'
UNTOUCHED_PLACEHOLDER='string_with_special_characters'
JWT_SECRET='string_without_special_characters'
EOF

    declare -A known_values=(["DOMAIN"]="example.com")
    declare -a secret_keys=("JWT_SECRET")

    render_environment_file "$template" "$target" known_values secret_keys

    grep -qxF "DOMAIN=example.com" "$target"
    grep -qxF "UNTOUCHED_PLACEHOLDER='string_with_special_characters'" "$target"
    ! grep -q "JWT_SECRET='string_without_special_characters'" "$target"
    [[ "$(grep '^JWT_SECRET=' "$target")" =~ ^JWT_SECRET=[0-9a-f]{64}$ ]]
}

@test "render_environment_file preserves an already-rendered value on a second run" {
    template="$BATS_TEST_TMPDIR/template.env"
    target="$BATS_TEST_TMPDIR/rendered.env"
    cat >"$template" <<'EOF'
DOMAIN='string_with_special_characters'
JWT_SECRET='string_without_special_characters'
EOF

    declare -A known_values=(["DOMAIN"]="example.com")
    declare -a secret_keys=("JWT_SECRET")

    render_environment_file "$template" "$target" known_values secret_keys
    first_secret=$(grep '^JWT_SECRET=' "$target")

    declare -A changed_known_values=(["DOMAIN"]="changed.example.com")
    render_environment_file "$template" "$target" changed_known_values secret_keys
    second_secret=$(grep '^JWT_SECRET=' "$target")

    grep -qxF "DOMAIN=example.com" "$target"
    [ "$first_secret" = "$second_secret" ]
}

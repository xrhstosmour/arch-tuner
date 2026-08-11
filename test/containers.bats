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

@test "get_containers_domain rejects an invalid domain and prompts again" {
    run bash -c "source '$containers_under_test' && printf 'not a domain\nexample.com\n' | get_containers_domain"

    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tail -n 1)" = "example.com" ]
}

@test "get_containers_domain persists the chosen domain and does not reprompt" {
    bash -c "source '$containers_under_test' && printf 'example.com\n' | get_containers_domain" >/dev/null

    run bash -c "source '$containers_under_test' && get_containers_domain </dev/null"

    [ "$status" -eq 0 ]
    [ "$output" = "example.com" ]
}

@test "get_acme_email rejects an invalid email and prompts again" {
    run bash -c "source '$containers_under_test' && printf 'not-an-email\nadmin@example.com\n' | get_acme_email"

    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tail -n 1)" = "admin@example.com" ]
}

@test "get_acme_email persists the chosen email and does not reprompt" {
    bash -c "source '$containers_under_test' && printf 'admin@example.com\n' | get_acme_email" >/dev/null

    run bash -c "source '$containers_under_test' && get_acme_email </dev/null"

    [ "$status" -eq 0 ]
    [ "$output" = "admin@example.com" ]
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

@test "render_environment_file preserves a value ending in '=', such as base64 padding, on a second run" {
    # Regression guard: "IFS='=' read" silently drops a trailing delimiter
    # with nothing after it, corrupting any value ending in "=" one
    # character at a time on every subsequent render.
    template="$BATS_TEST_TMPDIR/template.env"
    target="$BATS_TEST_TMPDIR/rendered.env"
    printf "ENCRYPTION_KEY='string_without_special_characters'\n" >"$template"

    declare -A known_values=(["ENCRYPTION_KEY"]="fake-base64-padding-test-value-not-a-real-secret==")
    declare -a secret_keys=()

    render_environment_file "$template" "$target" known_values secret_keys
    render_environment_file "$template" "$target" known_values secret_keys
    render_environment_file "$template" "$target" known_values secret_keys

    grep -qxF "ENCRYPTION_KEY=fake-base64-padding-test-value-not-a-real-secret==" "$target"
}

@test "get_containers_admin_username rejects a username with spaces and prompts again" {
    run bash -c "source '$containers_under_test' && printf 'bad name\ngoodname\n' | get_containers_admin_username"

    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tail -n 1)" = "goodname" ]
}

@test "get_containers_admin_email rejects an invalid email and prompts again" {
    run bash -c "source '$containers_under_test' && printf 'not-an-email\nadmin@example.com\n' | get_containers_admin_email"

    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tail -n 1)" = "admin@example.com" ]
}

@test "get_containers_admin_password rejects a value containing a dollar sign" {
    run bash -c "source '$containers_under_test' && printf 'has\$dollar123\nvalidpassword123\nvalidpassword123\n' | get_containers_admin_password"

    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tail -n 1)" = "validpassword123" ]
}

@test "get_containers_admin_password rejects a value shorter than 12 characters" {
    run bash -c "source '$containers_under_test' && printf 'short\nvalidpassword123\nvalidpassword123\n' | get_containers_admin_password"

    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tail -n 1)" = "validpassword123" ]
}

@test "get_containers_admin_password rejects a confirmation that does not match" {
    run bash -c "source '$containers_under_test' && printf 'validpassword123\nwrongconfirmation12\nvalidpassword123\nvalidpassword123\n' | get_containers_admin_password"

    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tail -n 1)" = "validpassword123" ]
}

@test "get_containers_admin_password persists the chosen password and does not reprompt" {
    bash -c "source '$containers_under_test' && printf 'validpassword123\nvalidpassword123\n' | get_containers_admin_password" >/dev/null

    run bash -c "source '$containers_under_test' && get_containers_admin_password </dev/null"

    [ "$status" -eq 0 ]
    [ "$output" = "validpassword123" ]
}

@test "read_environment_value extracts a key's value, tolerating '=' inside it" {
    target="$BATS_TEST_TMPDIR/dependency.env"
    printf 'POSTGRESQL_USER=arch_tuner\nPOSTGRESQL_PASSWORD=abc=def\n' >"$target"

    run read_environment_value "$target" "POSTGRESQL_PASSWORD"

    [ "$output" = "abc=def" ]
}

@test "ensure_postgresql_database uses a CREATE DATABASE guarded by a NOT EXISTS check, fed through stdin" {
    stdin_log="$BATS_TEST_TMPDIR/stdin.log"
    cat >"$fake_bin/docker" <<EOF
#!/usr/bin/env bash
echo "docker \$*" >> "$calls_log"
cat > "$stdin_log"
EOF
    chmod +x "$fake_bin/docker"
    PATH="$fake_bin:$PATH"

    ensure_postgresql_database "authelia" "arch_tuner"

    grep -q 'exec -i postgresql psql' "$calls_log"
    grep -q 'CREATE DATABASE .authelia.' "$stdin_log"
    grep -q 'NOT EXISTS' "$stdin_log"
    grep -qF '\gexec' "$stdin_log"
}

@test "generate_rsa_private_key returns a PKCS#8 PEM-formatted key" {
    run generate_rsa_private_key

    [ "$status" -eq 0 ]
    [[ "$output" == *"BEGIN PRIVATE KEY"* ]]
    [[ "$output" == *"END PRIVATE KEY"* ]]
}

@test "get_or_generate_file_secret generates and persists a file on first call" {
    target_file="$BATS_TEST_TMPDIR/secret.pem"

    run get_or_generate_file_secret "$target_file" "generate_rsa_private_key"

    [ "$status" -eq 0 ]
    [ -f "$target_file" ]
    [[ "$output" == *"BEGIN PRIVATE KEY"* ]]
}

@test "get_or_generate_file_secret returns the same content on a second call instead of regenerating" {
    target_file="$BATS_TEST_TMPDIR/secret.pem"

    first=$(get_or_generate_file_secret "$target_file" "generate_rsa_private_key")
    second=$(get_or_generate_file_secret "$target_file" "generate_rsa_private_key")

    [ "$first" = "$second" ]
}

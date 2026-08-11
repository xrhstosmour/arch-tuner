#!/usr/bin/env bats

setup() {
    traefik_script="$BATS_TEST_DIRNAME/../scripts/helpers/containers/traefik.sh"
    override_file="$BATS_TEST_DIRNAME/../scripts/configurations/containers/traefik/docker-compose.override.yml"
}

@test "traefik.sh checks both port 80 and 443 before starting" {
    grep -q 'for port in 80 443' "$traefik_script"
}

@test "traefik.sh never hardcodes the dashboard password" {
    ! grep -q 'dashboard_password=.\{0,5\}"[^$(]' "$traefik_script"
    grep -q 'get_or_generate_shared_secret "CONTAINERS_TRAEFIK_DASHBOARD_PASSWORD"' "$traefik_script"
}

@test "the override enables ACME HTTP-01, not upstream's commented-out TLS-ALPN-01 example" {
    grep -q 'acme.httpchallenge=true' "$override_file"
    grep -q 'acme.httpchallenge.entrypoint=web' "$override_file"
    ! grep -viE '^\s*#' "$override_file" | grep -qi 'tlschallenge'
}

@test "the override keeps every base command flag instead of dropping one on replace" {
    for flag in "providers.docker=true" "providers.file=true" "api.dashboard=true" "entrypoints.web.address=:80" "entrypoints.web_secure.address=:443"; do
        grep -qF -- "--$flag" "$override_file"
    done
}

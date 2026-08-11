#!/usr/bin/env bats

setup() {
    uptime_kuma_script="$BATS_TEST_DIRNAME/../scripts/helpers/containers/uptime-kuma.sh"
}

@test "uptime-kuma.sh closes its own published port and fronts it through Traefik" {
    grep -q 'ports: !reset \[\]' "$uptime_kuma_script"
    grep -q 'traefik.enable=true' "$uptime_kuma_script"
    grep -qF 'uptime_kuma_domain' "$uptime_kuma_script"
}

@test "uptime-kuma.sh bakes the domain in directly, template.env has no DOMAIN variable to reference" {
    ! grep -viE '^\s*#' "$uptime_kuma_script" | grep -qF '${DOMAIN'
}

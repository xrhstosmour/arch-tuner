#!/usr/bin/env bats

setup() {
    linkstack_script="$BATS_TEST_DIRNAME/../scripts/helpers/containers/linkstack.sh"
}

@test "linkstack.sh closes its own published ports and fronts it through Traefik" {
    grep -q 'ports: !reset \[\]' "$linkstack_script"
    grep -q 'traefik.enable=true' "$linkstack_script"
    grep -qF 'linkstack_domain' "$linkstack_script"
}

@test "linkstack.sh sets an explicit service port, it exposes 2 ports unlike Filestash/Uptime Kuma" {
    grep -q 'loadbalancer.server.port=80' "$linkstack_script"
}

@test "linkstack.sh bakes the domain in directly, template.env has no DOMAIN variable to reference" {
    ! grep -viE '^\s*#' "$linkstack_script" | grep -qF '${DOMAIN'
}

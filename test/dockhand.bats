#!/usr/bin/env bats

setup() {
    dockhand_script="$BATS_TEST_DIRNAME/../scripts/helpers/containers/dockhand.sh"
}

@test "dockhand.sh closes its own published port and fronts it through Traefik" {
    grep -q 'ports: !reset \[\]' "$dockhand_script"
    grep -q 'traefik.enable=true' "$dockhand_script"
    grep -qF 'dockhand_domain' "$dockhand_script"
}

@test "dockhand.sh bakes the domain in directly, template.env has no DOMAIN variable to reference" {
    ! grep -viE '^\s*#' "$dockhand_script" | grep -qF '${DOMAIN'
}

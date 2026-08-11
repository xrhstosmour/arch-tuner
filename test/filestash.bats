#!/usr/bin/env bats

setup() {
    filestash_script="$BATS_TEST_DIRNAME/../scripts/helpers/containers/filestash.sh"
}

@test "filestash.sh closes its own published port and fronts it through Traefik" {
    grep -q 'ports: !reset \[\]' "$filestash_script"
    grep -q 'traefik.enable=true' "$filestash_script"
    grep -qF 'filestash_domain' "$filestash_script"
}

@test "filestash.sh bakes the domain in directly, template.env has no DOMAIN variable to reference" {
    ! grep -viE '^\s*#' "$filestash_script" | grep -qF '${DOMAIN'
}

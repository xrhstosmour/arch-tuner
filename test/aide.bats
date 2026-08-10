#!/usr/bin/env bats

setup() {
    aide_conf="$BATS_TEST_DIRNAME/../scripts/configurations/security/aide/aide.conf"
}

@test "aide.conf never excludes critical account/privilege files from monitoring" {
    ! grep -qE '^(/etc/passwd|/etc/shadow|/etc/group|/etc/gshadow|/etc/sudoers)' "$aide_conf"
}

@test "aide.conf uses AIDE's negative selection syntax for noise-directory exclusions" {
    grep -qxF '!/proc' "$aide_conf"
    grep -qxF '!/tmp' "$aide_conf"
    # The old "= -" syntax is not valid AIDE negative selection.
    ! grep -qE '= -\s*$' "$aide_conf"
}

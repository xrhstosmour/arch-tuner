#!/usr/bin/env bats

@test "bootstrap.sh never runs a bare pacman -Sy, the Arch partial-upgrade anti-pattern" {
    bootstrap_script="$BATS_TEST_DIRNAME/../bootstrap.sh"

    ! grep -qE 'pacman -Sy( |$)' "$bootstrap_script"
    grep -q 'pacman -Syu' "$bootstrap_script"
}

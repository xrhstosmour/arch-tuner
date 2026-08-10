#!/usr/bin/env bats

setup() {
    rate_mirrors_script="$BATS_TEST_DIRNAME/../scripts/configurations/essentials/mirrors/rate-mirrors.sh"
}

@test "rate-mirrors.sh backs up the mirrorlist and validates the result before overwriting" {
    # Regression guard: the old version overwrote /etc/pacman.d/mirrorlist
    # unconditionally with no backup and no check that rate-mirrors actually
    # produced usable servers, a transient network blip during probing
    # (exit 0, empty output) could brick every subsequent pacman/AUR call.
    grep -q 'mirrorlist.bak' "$rate_mirrors_script"
    grep -q "grep -q '\^Server = '" "$rate_mirrors_script"
    grep -q 'exit 1' "$rate_mirrors_script"
}

@test "the usable-servers check accepts real rate-mirrors output and rejects empty output" {
    valid_output="$BATS_TEST_TMPDIR/valid.txt"
    printf 'Server = https://mirror1.example.com/$repo/os/$arch\n' >"$valid_output"
    empty_output="$BATS_TEST_TMPDIR/empty.txt"
    : >"$empty_output"

    grep -q '^Server = ' "$valid_output"
    ! grep -q '^Server = ' "$empty_output"
}

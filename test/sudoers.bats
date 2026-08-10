#!/usr/bin/env bats

@test "sudoers hardening drop-in never requires a tty, that breaks non-interactive sudo" {
    sudoers_drop_in="$BATS_TEST_DIRNAME/../scripts/configurations/security/sudoers/99-hardening"

    ! grep -q 'requiretty' "$sudoers_drop_in"
}

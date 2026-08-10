#!/usr/bin/env bats

@test "sudoers hardening drop-in never requires a tty, that breaks non-interactive sudo" {
    sudoers_drop_in="$BATS_TEST_DIRNAME/../scripts/configurations/security/sudoers/99-hardening"

    ! grep -q 'requiretty' "$sudoers_drop_in"
}

@test "sudoers.sh validates the drop-in with visudo before deploying it" {
    # Regression guard: a malformed drop-in breaks sudo for every user with
    # no safety net if it is copied into /etc/sudoers.d without validation.
    sudoers_script="$BATS_TEST_DIRNAME/../scripts/helpers/security/sudoers.sh"

    grep -q 'visudo -cf' "$sudoers_script"
}

#!/usr/bin/env bats

@test "sshd_config disables the keyboard-interactive/PAM password fallback too" {
    # PasswordAuthentication no alone can still leave password login
    # reachable via keyboard-interactive on modern OpenSSH when UsePAM yes.
    sshd_config="$BATS_TEST_DIRNAME/../scripts/configurations/security/ssh/sshd_config"

    grep -qxF 'KbdInteractiveAuthentication no' "$sshd_config"
}

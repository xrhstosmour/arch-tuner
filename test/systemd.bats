#!/usr/bin/env bats

setup() {
    systemd_script="$BATS_TEST_DIRNAME/../scripts/helpers/security/systemd.sh"
    sshd_drop_in="$BATS_TEST_DIRNAME/../scripts/configurations/security/systemd/99-hardening-sshd"
    chronyd_drop_in="$BATS_TEST_DIRNAME/../scripts/configurations/security/systemd/99-hardening-chronyd"
    update_service="$BATS_TEST_DIRNAME/../systemd/arch-tuner-update.service"
    update_timer="$BATS_TEST_DIRNAME/../systemd/arch-tuner-update.timer"
}

@test "sshd drop-in omits the directives that would permanently break sudo/su and scp/sftp" {
    ! grep -q '^NoNewPrivileges=' "$sshd_drop_in"
    ! grep -q '^ProtectSystem=' "$sshd_drop_in"
    ! grep -q '^ProtectHome=' "$sshd_drop_in"
}

@test "chronyd drop-in keeps the full hardening set" {
    grep -q '^NoNewPrivileges=yes' "$chronyd_drop_in"
    grep -q '^ProtectSystem=strict' "$chronyd_drop_in"
    grep -q '^ProtectHome=yes' "$chronyd_drop_in"
}

@test "systemd.sh maps sshd and chronyd to distinct drop-in files, not one shared file" {
    grep -q '\["sshd"\]=.*99-hardening-sshd' "$systemd_script"
    grep -q '\["chronyd"\]=.*99-hardening-chronyd' "$systemd_script"
}

@test "the auto-update service skips sandboxing directives that would break package installation" {
    # pacman needs broad filesystem write access and legitimately installs
    # setuid binaries as part of normal upgrades.
    ! grep -q '^ProtectSystem=' "$update_service"
    ! grep -q '^ProtectHome=' "$update_service"
    ! grep -q '^RestrictSUIDSGID=' "$update_service"
}

@test "the auto-update service adds safe sandboxing directives" {
    grep -q '^NoNewPrivileges=yes' "$update_service"
    grep -q '^ProtectClock=yes' "$update_service"
}

@test "the auto-update timer randomizes its start time to avoid a thundering herd" {
    grep -q '^RandomizedDelaySec=' "$update_timer"
}

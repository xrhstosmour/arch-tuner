#!/usr/bin/env bats

@test "install.sh reboots after every phase, not just security" {
    # Regression guard: essentials and privacy shared one reboot_system call,
    # security had its own, only the security one survived a past refactor.
    install_script="$BATS_TEST_DIRNAME/../install.sh"

    [ "$(grep -c 'reboot_system ' "$install_script")" -eq 2 ]
}

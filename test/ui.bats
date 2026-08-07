#!/usr/bin/env bats

setup() {
    ui_under_test="$BATS_TEST_DIRNAME/../scripts/helpers/functions/ui.sh"

    export ARCH_TUNER_STATE_DIRECTORY="$BATS_TEST_TMPDIR"
}

@test "get_ssh_port rejects the classic port 22 and prompts again" {
    run bash -c "source '$ui_under_test' && printf '22\n2244\n' | get_ssh_port"

    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tail -n 1)" = "2244" ]
}

@test "get_ssh_port rejects a non-numeric or out-of-range port" {
    run bash -c "source '$ui_under_test' && printf 'abc\n70000\n2244\n' | get_ssh_port"

    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tail -n 1)" = "2244" ]
}

@test "get_ssh_port accepts a valid custom port on the first try" {
    run bash -c "source '$ui_under_test' && printf '2244\n' | get_ssh_port"

    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tail -n 1)" = "2244" ]
}

@test "get_ssh_port persists the chosen port and does not reprompt" {
    bash -c "source '$ui_under_test' && printf '2244\n' | get_ssh_port" >/dev/null

    run bash -c "source '$ui_under_test' && get_ssh_port </dev/null"

    [ "$status" -eq 0 ]
    [ "$output" = "2244" ]
}

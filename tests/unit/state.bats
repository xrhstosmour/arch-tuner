#!/usr/bin/env bats

load test_helper/common

setup() {
    setup_mock_bin
    export ARCH_TUNER_STATE_DIRECTORY="$BATS_TEST_TMPDIR/state"
    # shellcheck disable=SC1091
    source "$FUNCTIONS_DIRECTORY/state.sh"
}

@test "change_flag_value writes a numeric value unquoted" {
    change_flag_value "SOME_FLAG" 1
    grep -qxF 'SOME_FLAG=1' "$STATE_FILE"
}

@test "change_flag_value writes a non-numeric value quoted" {
    change_flag_value "SOME_FLAG" "server"
    grep -qxF 'SOME_FLAG="server"' "$STATE_FILE"
}

@test "change_flag_value replaces a previous value for the same flag" {
    change_flag_value "SOME_FLAG" 0
    change_flag_value "SOME_FLAG" 1
    [ "$(grep -c '^SOME_FLAG=' "$STATE_FILE")" -eq 1 ]
    grep -qxF 'SOME_FLAG=1' "$STATE_FILE"
}

@test "change_flag_value preserves other flags already in the state file" {
    change_flag_value "FIRST_FLAG" 1
    change_flag_value "SECOND_FLAG" "value"
    grep -qxF 'FIRST_FLAG=1' "$STATE_FILE"
    grep -qxF 'SECOND_FLAG="value"' "$STATE_FILE"
}

@test "change_flag_value rejects a value containing a double quote" {
    run change_flag_value "SOME_FLAG" 'bad"value'
    [ "$status" -eq 1 ]
    [ ! -f "$STATE_FILE" ]
}

@test "change_flag_value rejects a value containing a backslash" {
    run change_flag_value "SOME_FLAG" 'bad\value'
    [ "$status" -eq 1 ]
}

@test "change_flag_value rejects a value containing a newline" {
    run change_flag_value "SOME_FLAG" "$(printf 'bad\nvalue')"
    [ "$status" -eq 1 ]
}

@test "source_state loads flags from an existing state file" {
    change_flag_value "SOURCED_FLAG" 1
    unset SOURCED_FLAG
    source_state
    [ "$SOURCED_FLAG" -eq 1 ]
}

@test "source_state is a no-op when no state file exists" {
    run source_state
    [ "$status" -eq 0 ]
}

@test "reset_state removes an existing state file" {
    change_flag_value "SOME_FLAG" 1
    [ -f "$STATE_FILE" ]
    reset_state
    [ ! -f "$STATE_FILE" ]
}

@test "reset_state is a no-op when no state file exists" {
    run reset_state
    [ "$status" -eq 0 ]
}

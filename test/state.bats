#!/usr/bin/env bats

setup() {
    state_under_test="$BATS_TEST_DIRNAME/../scripts/helpers/functions/state.sh"
    system_under_test="$BATS_TEST_DIRNAME/../scripts/helpers/functions/system.sh"

    export ARCH_TUNER_STATE_DIRECTORY="$BATS_TEST_TMPDIR"
    source "$state_under_test"
}

@test "change_flag_value writes the literal flag name and value" {
    change_flag_value "EXAMPLE_FLAG" "1"

    grep -qxF 'EXAMPLE_FLAG=1' "$STATE_FILE"
}

@test "change_flag_value overwrites an existing flag rather than duplicating it" {
    change_flag_value "EXAMPLE_FLAG" "0"
    change_flag_value "EXAMPLE_FLAG" "1"

    [ "$(grep -c '^EXAMPLE_FLAG=' "$STATE_FILE")" -eq 1 ]
    grep -qxF 'EXAMPLE_FLAG=1' "$STATE_FILE"
}

@test "reset_system_to_clean_state calls change_flag_value with literal flag names" {
    # Regression guard for the value/name argument-swap bug: every
    # change_flag_value call inside the function must pass a literal name,
    # never a variable expansion like "$SOME_FLAG".
    function_body=$(awk '/^reset_system_to_clean_state\(\)/,/^}/' "$system_under_test")

    ! grep -E 'change_flag_value "\$[A-Z_]+"' <<<"$function_body"
}

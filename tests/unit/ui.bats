#!/usr/bin/env bats

load test_helper/common

setup() {
    # shellcheck disable=SC1091
    source "$FUNCTIONS_DIRECTORY/ui.sh"
}

@test "prompt_user_input returns the typed value" {
    result=$(prompt_user_input "prompt" "default" <<<"typed" 2>/dev/null)
    [ "$result" = "typed" ]
}

@test "prompt_user_input falls back to the default value when input is empty" {
    result=$(prompt_user_input "prompt" "default" <<<"" 2>/dev/null)
    [ "$result" = "default" ]
}

@test "choose_option returns the option selected by number" {
    result=$(choose_option "prompt" "alpha" "beta" "gamma" <<<"2" 2>/dev/null)
    [ "$result" = "beta" ]
}

@test "choose_option defaults to the first option when input is empty" {
    result=$(choose_option "prompt" "alpha" "beta" <<<"" 2>/dev/null)
    [ "$result" = "alpha" ]
}

@test "ask_user_before_execution returns n without executing anything when declined" {
    marker="$BATS_TEST_TMPDIR/marker"
    result=$(ask_user_before_execution "Proceed?" "true" "touch $marker" <<<"n" 2>/dev/null)
    [ "$result" = "n" ]
    [ ! -f "$marker" ]
}

@test "ask_user_before_execution executes a plain command when approved" {
    marker="$BATS_TEST_TMPDIR/marker"
    result=$(ask_user_before_execution "Proceed?" "true" "touch $marker" <<<"y" 2>/dev/null)
    [ "$result" = "y" ]
    [ -f "$marker" ]
}

@test "ask_user_before_execution invokes a named function via the script#function syntax" {
    marker="$BATS_TEST_TMPDIR/marker"
    cat >"$BATS_TEST_TMPDIR/helper.sh" <<SCRIPT
mark_called() {
    touch "$marker"
}
SCRIPT
    result=$(ask_user_before_execution "Proceed?" "true" "$BATS_TEST_TMPDIR/helper.sh#mark_called" <<<"y" 2>/dev/null)
    [ "$result" = "y" ]
    [ -f "$marker" ]
}

@test "ask_user_before_execution executes an existing script file directly" {
    marker="$BATS_TEST_TMPDIR/marker"
    cat >"$BATS_TEST_TMPDIR/script.sh" <<SCRIPT
#!/bin/sh
touch "$marker"
SCRIPT
    chmod +x "$BATS_TEST_TMPDIR/script.sh"
    result=$(ask_user_before_execution "Proceed?" "true" "$BATS_TEST_TMPDIR/script.sh" <<<"y" 2>/dev/null)
    [ "$result" = "y" ]
    [ -f "$marker" ]
}

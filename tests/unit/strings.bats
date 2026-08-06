#!/usr/bin/env bats

load test_helper/common

setup() {
    # shellcheck disable=SC1091
    source "$FUNCTIONS_DIRECTORY/strings.sh"
}

@test "trim_string removes leading and trailing whitespace" {
    run trim_string "   padded value   "
    [ "$status" -eq 0 ]
    [ "$output" = "padded value" ]
}

@test "trim_string leaves internal whitespace untouched" {
    run trim_string "  one two  "
    [ "$status" -eq 0 ]
    [ "$output" = "one two" ]
}

@test "trim_string returns an already-trimmed string unchanged" {
    run trim_string "clean"
    [ "$status" -eq 0 ]
    [ "$output" = "clean" ]
}

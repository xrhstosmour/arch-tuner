#!/usr/bin/env bats

load test_helper/common

setup() {
    # shellcheck disable=SC1091
    source "$FUNCTIONS_DIRECTORY/logs.sh"
}

@test "log_info prints the message with a leading blank line by default" {
    run log_info "hello"
    [ "$status" -eq 0 ]
    stripped="$(strip_ansi "$output")"
    [ "$stripped" = $'\nhello' ]
}

@test "log_info -n prints the message without a leading blank line" {
    run log_info -n "hello"
    [ "$status" -eq 0 ]
    stripped="$(strip_ansi "$output")"
    [ "$stripped" = "hello" ]
}

@test "log_success prints the given message" {
    run log_success -n "done"
    [ "$status" -eq 0 ]
    stripped="$(strip_ansi "$output")"
    [ "$stripped" = "done" ]
}

@test "log_warning prints the given message" {
    run log_warning -n "careful"
    [ "$status" -eq 0 ]
    stripped="$(strip_ansi "$output")"
    [ "$stripped" = "careful" ]
}

@test "log_error prints the given message" {
    run log_error -n "broken"
    [ "$status" -eq 0 ]
    stripped="$(strip_ansi "$output")"
    [ "$stripped" = "broken" ]
}

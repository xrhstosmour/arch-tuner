#!/usr/bin/env bats

setup() {
    filesystem_under_test="$BATS_TEST_DIRNAME/../scripts/helpers/functions/filesystem.sh"

    # Stub sudo so the sourced functions run as the test user against files
    # already owned by that user, instead of requiring real root.
    sudo() { command "$@"; }
    export -f sudo

    source "$filesystem_under_test"
}

@test "append_line_to_file appends a missing line and prints only true" {
    local file="$BATS_TEST_TMPDIR/target.txt"
    : >"$file"

    run append_line_to_file "$file" "hello world" ""

    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
    grep -qxF "hello world" "$file"
}

@test "append_line_to_file skips an existing line and prints only false" {
    local file="$BATS_TEST_TMPDIR/target.txt"
    echo "hello world" >"$file"

    run append_line_to_file "$file" "hello world" ""

    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
}

@test "update_mount_options no longer writes fstab to a fixed /tmp path" {
    ! grep -q '/tmp/fstab.tmp' "$filesystem_under_test"
    grep -q 'mktemp' "$filesystem_under_test"
}

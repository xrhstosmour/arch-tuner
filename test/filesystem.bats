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

@test "change_configuration creates a missing parent directory before writing" {
    local file="$BATS_TEST_TMPDIR/not-yet-created/paru.conf"

    change_configuration "CleanMethod" " = KeepInstalled" "$file"

    [ -f "$file" ]
    grep -qxF "CleanMethod = KeepInstalled" "$file"
}

# update_mount_options canonicalizes the merged option set via
# "sort | tr '\n' ','", exercised directly here since the function itself
# always targets the real /etc/fstab.
canonicalize_options() {
    tr ',' '\n' <<<"$1" | sort | tr '\n' ','
}

@test "update_mount_options's sorted comparison treats reordered option sets as identical" {
    same_order_a=$(canonicalize_options "noexec,nosuid,nodev")
    same_order_b=$(canonicalize_options "nodev,noexec,nosuid")

    [ "$same_order_a" = "$same_order_b" ]
}

@test "update_mount_options's sorted comparison still detects a real option change" {
    with_nodev=$(canonicalize_options "nodev,noexec")
    without_nodev=$(canonicalize_options "noexec")

    [ "$with_nodev" != "$without_nodev" ]
}

@test "update_mount_options sorts both sides before comparing, not raw hash order" {
    grep -q 'current_options_sorted' "$filesystem_under_test"
    grep -q 'printf .%s\\n. "\${!unique_options\[@\]}" | sort' "$filesystem_under_test"
}

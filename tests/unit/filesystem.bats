#!/usr/bin/env bats

load test_helper/common

setup() {
    setup_mock_bin
    # shellcheck disable=SC1091
    source "$FUNCTIONS_DIRECTORY/filesystem.sh"
}

@test "compare_files reports false when the target file does not exist" {
    run compare_files "$BATS_TEST_TMPDIR/missing" "$BATS_TEST_TMPDIR/missing-source"
    [ "$output" = "false" ]
}

@test "compare_files reports true when target and source are identical" {
    echo "same" >"$BATS_TEST_TMPDIR/source"
    echo "same" >"$BATS_TEST_TMPDIR/target"
    run compare_files "$BATS_TEST_TMPDIR/target" "$BATS_TEST_TMPDIR/source"
    [ "$output" = "true" ]
}

@test "compare_files reports false when target and source differ" {
    echo "one" >"$BATS_TEST_TMPDIR/source"
    echo "two" >"$BATS_TEST_TMPDIR/target"
    run compare_files "$BATS_TEST_TMPDIR/target" "$BATS_TEST_TMPDIR/source"
    [ "$output" = "false" ]
}

@test "directory_exists_in_list finds a directory present in the list" {
    excluded=("/sys" "/proc" "/boot")
    run directory_exists_in_list "/proc" excluded
    [ "$output" = "true" ]
}

@test "directory_exists_in_list reports false for a directory not in the list" {
    excluded=("/sys" "/proc" "/boot")
    run directory_exists_in_list "/etc" excluded
    [ "$output" = "false" ]
}

@test "is_file_contained_in_another reports true when every line is present" {
    printf 'a\nb\nc\n' >"$BATS_TEST_TMPDIR/container"
    printf 'a\nb\n' >"$BATS_TEST_TMPDIR/subset"
    run is_file_contained_in_another "$BATS_TEST_TMPDIR/container" "$BATS_TEST_TMPDIR/subset"
    [ "$output" = "true" ]
}

@test "is_file_contained_in_another reports false when a line is missing" {
    printf 'a\nb\n' >"$BATS_TEST_TMPDIR/container"
    printf 'a\nc\n' >"$BATS_TEST_TMPDIR/other"
    run is_file_contained_in_another "$BATS_TEST_TMPDIR/container" "$BATS_TEST_TMPDIR/other"
    [ "$output" = "false" ]
}

@test "is_file_contained_in_another reports false when either file is empty" {
    : >"$BATS_TEST_TMPDIR/empty"
    printf 'a\n' >"$BATS_TEST_TMPDIR/other"
    run is_file_contained_in_another "$BATS_TEST_TMPDIR/empty" "$BATS_TEST_TMPDIR/other"
    [ "$output" = "false" ]
}

@test "change_configuration appends a new key that is not present yet" {
    : >"$BATS_TEST_TMPDIR/config"
    change_configuration "Port" " 2222" "$BATS_TEST_TMPDIR/config"
    grep -qxF "Port 2222" "$BATS_TEST_TMPDIR/config"
}

@test "change_configuration replaces an existing uncommented key" {
    printf 'Port 22\n' >"$BATS_TEST_TMPDIR/config"
    change_configuration "Port" " 2222" "$BATS_TEST_TMPDIR/config"
    [ "$(grep -c '^Port' "$BATS_TEST_TMPDIR/config")" -eq 1 ]
    grep -qxF "Port 2222" "$BATS_TEST_TMPDIR/config"
}

@test "change_configuration replaces a commented-out key in place" {
    printf '#Port 22\n' >"$BATS_TEST_TMPDIR/config"
    change_configuration "Port" " 2222" "$BATS_TEST_TMPDIR/config"
    grep -qxF "Port 2222" "$BATS_TEST_TMPDIR/config"
}

@test "append_line_to_file adds a missing line and reports true" {
    : >"$BATS_TEST_TMPDIR/config"
    run append_line_to_file "$BATS_TEST_TMPDIR/config" "new line" ""
    [[ "$output" == *"true"* ]]
    grep -qxF "new line" "$BATS_TEST_TMPDIR/config"
}

@test "append_line_to_file reports false when the line already exists" {
    printf 'existing line\n' >"$BATS_TEST_TMPDIR/config"
    run append_line_to_file "$BATS_TEST_TMPDIR/config" "existing line" ""
    [[ "$output" == *"false"* ]]
    [ "$(grep -c '^existing line$' "$BATS_TEST_TMPDIR/config")" -eq 1 ]
}

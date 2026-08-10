#!/usr/bin/env bats

setup() {
    ids_script="$BATS_TEST_DIRNAME/../scripts/helpers/security/ids.sh"
}

# Exercises the exact special-bits formula ids.sh uses, to prove it detects
# suid and sgid independently, including when both are set at once (mode
# 6755, which a "4*"/"2*" string-prefix check would miss entirely since the
# digit starts with "6").
special_bits_of() {
    local file_mode="$1"
    local special_bits
    special_bits=$(printf '%04o' "0$file_mode")
    special_bits=${special_bits:0:1}
    echo "$special_bits"
}

@test "detects setuid-only mode (4755)" {
    special_bits=$(special_bits_of 4755)
    [ "$(( special_bits & 4 ))" -ne 0 ]
    [ "$(( special_bits & 2 ))" -eq 0 ]
}

@test "detects setgid-only mode (2755)" {
    special_bits=$(special_bits_of 2755)
    [ "$(( special_bits & 4 ))" -eq 0 ]
    [ "$(( special_bits & 2 ))" -ne 0 ]
}

@test "detects combined setuid+setgid mode (6755), the case the old 4*/2* prefix check missed" {
    special_bits=$(special_bits_of 6755)
    [ "$(( special_bits & 4 ))" -ne 0 ]
    [ "$(( special_bits & 2 ))" -ne 0 ]
}

@test "detects neither bit for a plain mode (755)" {
    special_bits=$(special_bits_of 755)
    [ "$(( special_bits & 4 ))" -eq 0 ]
    [ "$(( special_bits & 2 ))" -eq 0 ]
}

@test "ids.sh uses the bitwise special-bits check, not a 4*/2* string prefix" {
    ! grep -qE '== 4\*|== 2\*' "$ids_script"
    grep -q 'special_bits & 4' "$ids_script"
    grep -q 'special_bits & 2' "$ids_script"
}

@test "ids.sh reads find results NUL-separated, not an unquoted word-split loop" {
    ! grep -qE '^for binary_file in \$suid_sgid_binary_files' "$ids_script"
    grep -q -- '-print0' "$ids_script"
    grep -q "read -r -d ''" "$ids_script"
}

@test "a NUL-separated find/read loop keeps a path containing whitespace intact" {
    directory_with_space="$BATS_TEST_TMPDIR/dir with space"
    mkdir -p "$directory_with_space"
    binary_file="$directory_with_space/binary"
    touch "$binary_file"
    chmod u+s "$binary_file"

    files=()
    while IFS= read -r -d '' found; do
        files+=("$found")
    done < <(find "$BATS_TEST_TMPDIR" -type f -perm -4000 -print0 2>/dev/null)

    [ "${#files[@]}" -eq 1 ]
    [ "${files[0]}" = "$binary_file" ]
}

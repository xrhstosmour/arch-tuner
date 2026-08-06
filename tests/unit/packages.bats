#!/usr/bin/env bats

load test_helper/common

# process_package is only ever invoked from within install_packages, and
# relies on that caller's local "manager" variable via bash dynamic scoping
# (it is not one of process_package's own parameters). Tests below drive it
# through install_packages, its only real call path, rather than calling it
# directly with different assumptions.

setup() {
    setup_mock_bin
    MOCK_STATE_DIRECTORY="$BATS_TEST_TMPDIR/pacman-state"
    CALL_LOG="$BATS_TEST_TMPDIR/pacman-calls.log"
    mkdir -p "$MOCK_STATE_DIRECTORY"
    : >"$CALL_LOG"
    create_mock pacman '
state_directory="'"$MOCK_STATE_DIRECTORY"'"
echo "$*" >>"'"$CALL_LOG"'"
case "$1" in
-Qq)
    [ -f "$state_directory/installed-$2" ] && exit 0 || exit 1
    ;;
-S)
    shift
    for arg in "$@"; do
        case "$arg" in
        --noconfirm | --needed | --mflags | --nocheck) ;;
        *) touch "$state_directory/installed-$arg" ;;
        esac
    done
    ;;
esac
'
    # shellcheck disable=SC1091
    source "$FUNCTIONS_DIRECTORY/packages.sh"
}

@test "are_packages_installed reports true when every package is installed" {
    touch "$MOCK_STATE_DIRECTORY/installed-git"
    touch "$MOCK_STATE_DIRECTORY/installed-curl"
    run are_packages_installed "git curl" "pacman"
    [ "$output" = "true" ]
}

@test "are_packages_installed reports false when a package is missing" {
    touch "$MOCK_STATE_DIRECTORY/installed-git"
    run are_packages_installed "git curl" "pacman"
    [ "$output" = "false" ]
}

@test "are_packages_installed reads packages from a file, skipping comments and blanks" {
    touch "$MOCK_STATE_DIRECTORY/installed-git"
    printf '# comment\n\ngit\n' >"$BATS_TEST_TMPDIR/packages.txt"
    run are_packages_installed "$BATS_TEST_TMPDIR/packages.txt" "pacman"
    [ "$output" = "true" ]
}

@test "are_packages_installed rejects an unsupported package manager" {
    run are_packages_installed "git" "some-other-manager"
    [ "$status" -eq 1 ]
}

@test "install_packages installs every package listed in a file" {
    printf 'git\ncurl\n' >"$BATS_TEST_TMPDIR/packages.txt"
    install_packages "$BATS_TEST_TMPDIR/packages.txt" "pacman"
    [ -f "$MOCK_STATE_DIRECTORY/installed-git" ]
    [ -f "$MOCK_STATE_DIRECTORY/installed-curl" ]
}

@test "install_packages installs every package listed in a space separated string" {
    install_packages "git curl" "pacman"
    [ -f "$MOCK_STATE_DIRECTORY/installed-git" ]
    [ -f "$MOCK_STATE_DIRECTORY/installed-curl" ]
}

@test "install_packages skips a package that is already installed" {
    touch "$MOCK_STATE_DIRECTORY/installed-git"
    install_packages "git" "pacman"
    ! grep -q -- '^-S ' "$CALL_LOG"
}

@test "install_packages skips comment and blank lines in a package file" {
    printf '# comment\n\ngit\n' >"$BATS_TEST_TMPDIR/packages.txt"
    install_packages "$BATS_TEST_TMPDIR/packages.txt" "pacman"
    [ -f "$MOCK_STATE_DIRECTORY/installed-git" ]
    [ "$(grep -c -- '^-S ' "$CALL_LOG")" -eq 1 ]
}

@test "install_packages strips a leading '!' and disables package tests" {
    install_packages "!git" "pacman"
    [ -f "$MOCK_STATE_DIRECTORY/installed-git" ]
    grep -qxF -- '-S --noconfirm --needed --mflags --nocheck git' "$CALL_LOG"
}

@test "install_packages rejects an unsupported package manager" {
    run install_packages "git" "some-other-manager"
    [ "$status" -eq 1 ]
}

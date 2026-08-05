#!/usr/bin/env bats

setup() {
    packages_under_test="$BATS_TEST_DIRNAME/../scripts/helpers/functions/packages.sh"

    fake_bin="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$fake_bin"
    calls_log="$BATS_TEST_TMPDIR/calls.log"
    : >"$calls_log"

    cat >"$fake_bin/fakepacman" <<EOF
#!/usr/bin/env bash
echo "call: \$*" >> "$calls_log"
if [ "\$1" = "-Qq" ]; then
    printf 'bash\ngit\ncurl\n'
fi
EOF
    chmod +x "$fake_bin/fakepacman"
    PATH="$fake_bin:$PATH"

    sudo() { command "$@"; }
    export -f sudo

    source "$BATS_TEST_DIRNAME/../scripts/helpers/functions/logs.sh"
    source "$BATS_TEST_DIRNAME/../scripts/helpers/functions/strings.sh"
    source "$packages_under_test"
}

@test "are_packages_installed shells out to the package manager only once" {
    ARCH_PACKAGE_MANAGER="fakepacman"

    run are_packages_installed "bash git curl" "fakepacman"

    [ "$output" = "true" ]
    [ "$(wc -l <"$calls_log" | tr -d ' ')" -eq 1 ]
}

@test "are_packages_installed detects a missing package" {
    ARCH_PACKAGE_MANAGER="fakepacman"

    run are_packages_installed "bash missing-package" "fakepacman"

    [ "$output" = "false" ]
}

@test "are_packages_installed falls back to command -v when no package manager is given, even with an empty AUR_PACKAGE_MANAGER" {
    AUR_PACKAGE_MANAGER=""

    run are_packages_installed "bash ls" "$AUR_PACKAGE_MANAGER"

    [ "$output" = "true" ]
    [ ! -s "$calls_log" ]
}

@test "install_packages lists installed packages once and installs only the missing, applying --nocheck only to !-prefixed packages" {
    ARCH_PACKAGE_MANAGER="fakepacman"
    printf 'bash\nwget\n!vim\n# comment\n\n' >"$BATS_TEST_TMPDIR/packages.txt"

    install_packages "$BATS_TEST_TMPDIR/packages.txt" "fakepacman" "Installing..."

    [ "$(grep -c '^call: -Qq$' "$calls_log")" -eq 1 ]
    [ "$(grep -c '^call: -S' "$calls_log")" -eq 2 ]
    grep -qxF 'call: -S --noconfirm --needed wget' "$calls_log"
    grep -qxF 'call: -S --noconfirm --needed --mflags --nocheck vim' "$calls_log"
    ! grep -q -- '-S.*bash' "$calls_log"
}

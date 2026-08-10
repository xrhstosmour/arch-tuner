#!/usr/bin/env bats

setup() {
    system_under_test="$BATS_TEST_DIRNAME/../scripts/helpers/functions/system.sh"

    export ARCH_TUNER_STATE_DIRECTORY="$BATS_TEST_TMPDIR"

    fake_bin="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$fake_bin"
    calls_log="$BATS_TEST_TMPDIR/calls.log"
    : >"$calls_log"

    # Fake pacman: lists three installed packages, and logs each invocation
    # with %q-encoded arguments so an argument containing embedded newlines
    # (the collapsed-list bug) is visible as one escaped token instead of
    # silently splitting the log line.
    cat >"$fake_bin/fakepacman" <<EOF
#!/usr/bin/env bash
{
    printf 'call:'
    for arg in "\$@"; do
        printf ' %q' "\$arg"
    done
    printf '\n'
} >> "$calls_log"
case "\$1" in
-Qqe) printf 'bash\ngit\ncurl\n' ;;
esac
EOF
    chmod +x "$fake_bin/fakepacman"

    cat >"$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
output_next=0
for arg in "$@"; do
    if [ "$output_next" = "1" ]; then
        printf 'bash 1.0\n' >"$arg"
        output_next=0
    elif [ "$arg" = "-o" ]; then
        output_next=1
    fi
done
EOF
    chmod +x "$fake_bin/curl"

    cat >"$fake_bin/chsh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$fake_bin/chsh"

    # Plain "pacman" (distinct from the configured $ARCH_PACKAGE_MANAGER) is
    # used by reset_system_to_clean_state for read-only "-Q" existence
    # checks. Always report "not installed" so the essential/fresh-install
    # asexplicit loops stay no-ops for this test.
    cat >"$fake_bin/pacman" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
    chmod +x "$fake_bin/pacman"

    # A real "sudo" executable on PATH, not just an exported function: xargs
    # execs "sudo" as a new process image, which does not see bash functions
    # exported into the environment, only PATH-resolved binaries.
    cat >"$fake_bin/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
    chmod +x "$fake_bin/sudo"

    PATH="$fake_bin:$PATH"

    sudo() { command "$@"; }
    export -f sudo

    source "$BATS_TEST_DIRNAME/../scripts/helpers/functions/logs.sh"
    source "$BATS_TEST_DIRNAME/../scripts/helpers/functions/strings.sh"
    source "$BATS_TEST_DIRNAME/../scripts/helpers/functions/state.sh"
    source "$BATS_TEST_DIRNAME/../scripts/core/flags.sh"
    source "$system_under_test"
}

@test "reset_system_to_clean_state marks packages as deps with one argument per package" {
    # constants.sh (sourced transitively via logs.sh) sets this to "pacman"
    # by default; override after setup's sourcing, like packages.bats does.
    ARCH_PACKAGE_MANAGER="fakepacman"

    run reset_system_to_clean_state

    [ "$status" -eq 0 ]

    asdeps_call=$(grep '^call: -D --asdeps' "$calls_log")
    [ -n "$asdeps_call" ]
    # A collapsed multi-line blob would %q-encode as a single $'bash\ngit\ncurl'
    # token; each package must instead be its own plain argument.
    [[ "$asdeps_call" != *'\n'* ]]
    [[ "$asdeps_call" == "call: -D --asdeps -- bash git curl" ]]
}

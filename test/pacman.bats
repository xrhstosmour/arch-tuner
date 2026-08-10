#!/usr/bin/env bats

setup() {
    pacman_script="$BATS_TEST_DIRNAME/../scripts/helpers/essentials/pacman.sh"

    # change_configuration uses GNU sed's "-i" (no backup-suffix argument),
    # the target Arch Linux systems ship GNU sed, this dev machine may not.
    fake_bin="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$fake_bin"
    cat >"$fake_bin/sed" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "-i" ] && /usr/bin/sed --version >/dev/null 2>&1; then
    # GNU sed: -i with no attached suffix already means in-place, no backup.
    exec /usr/bin/sed "$@"
elif [ "$1" = "-i" ]; then
    # BSD sed: -i requires an explicit (possibly empty) backup suffix arg.
    shift
    exec /usr/bin/sed -i '' "$@"
else
    exec /usr/bin/sed "$@"
fi
EOF
    chmod +x "$fake_bin/sed"
    PATH="$fake_bin:$PATH"

    sudo() { command "$@"; }
    export -f sudo

    source "$BATS_TEST_DIRNAME/../scripts/helpers/functions/logs.sh"
    source "$BATS_TEST_DIRNAME/../scripts/helpers/functions/filesystem.sh"
}

@test "pacman.sh no longer appends SigLevel hardening via append_line_to_file" {
    # Regression guard: append_line_to_file dedupes on an exact line match,
    # which never matches the shipped "SigLevel = Required DatabaseOptional"
    # default, so it always appended at the end of the file, landing inside
    # whichever repo section happened to be last instead of [options].
    ! grep -q 'append_line_to_file.*SigLevel' "$pacman_script"
    grep -q 'change_configuration "SigLevel"' "$pacman_script"
}

@test "change_configuration replaces the default SigLevel in place, under [options]" {
    local pacman_conf="$BATS_TEST_TMPDIR/pacman.conf"
    cat >"$pacman_conf" <<'EOF'
[options]
Color
SigLevel    = Required DatabaseOptional

[core]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

    change_configuration "SigLevel" " = Required DatabaseOptional TrustedOnly" "$pacman_conf"

    # The hardened line must replace the original SigLevel line under
    # [options], not get appended after the last repo section.
    options_section=$(awk '/^\[options\]/{flag=1} /^\[core\]/{flag=0} flag' "$pacman_conf")
    grep -qxF "SigLevel = Required DatabaseOptional TrustedOnly" <<<"$options_section"
    [ "$(grep -c '^SigLevel' "$pacman_conf")" -eq 1 ]
    [ "$(tail -n 1 "$pacman_conf")" != "SigLevel = Required DatabaseOptional TrustedOnly" ]
}

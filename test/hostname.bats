#!/usr/bin/env bats

setup() {
    hostname_under_test="$BATS_TEST_DIRNAME/../scripts/helpers/essentials/hostname.sh"
    export ARCH_TUNER_STATE_DIRECTORY="$BATS_TEST_TMPDIR"

    stub_directory="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$stub_directory"

    cat >"$stub_directory/sudo" <<'EOS'
#!/bin/bash
exec "$@"
EOS
    chmod +x "$stub_directory/sudo"

    export HOSTNAME_STUB_FILE="$BATS_TEST_TMPDIR/hostname_set_to"
    cat >"$stub_directory/hostnamectl" <<EOS
#!/bin/bash
case "\$1" in
--static) echo "archlinux" ;;
set-hostname) echo "\$2" >"$HOSTNAME_STUB_FILE" ;;
esac
EOS
    chmod +x "$stub_directory/hostnamectl"

    export PATH="$stub_directory:$PATH"
}

@test "hostname.sh rejects an invalid hostname and accepts a valid one" {
    run bash -c "printf 'Not_Valid!\nmy-host\n' | bash '$hostname_under_test'"

    [ "$status" -eq 0 ]
    [ "$(cat "$HOSTNAME_STUB_FILE")" = "my-host" ]
}

@test "hostname.sh persists HOSTNAME_SET after setting the hostname" {
    bash -c "printf 'my-host\n' | bash '$hostname_under_test'" >/dev/null

    grep -qxF 'HOSTNAME_SET=1' "$ARCH_TUNER_STATE_DIRECTORY/state.sh"
}

@test "hostname.sh does not prompt again once HOSTNAME_SET is 1" {
    bash -c "printf 'my-host\n' | bash '$hostname_under_test'" >/dev/null

    run bash -c "bash '$hostname_under_test' </dev/null"

    [ "$status" -eq 0 ]
}

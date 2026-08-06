#!/usr/bin/env bash

# Shared bats helpers: locate the functions library under test and provide
# PATH-scoped mock executables so tests never touch a real system.

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

# shellcheck disable=SC2034 # Reason: consumed by the bats files that load this helper.
FUNCTIONS_DIRECTORY="$REPOSITORY_ROOT/scripts/helpers/functions"

# Creates an isolated directory on PATH for mock executables and a permissive
# sudo mock that just runs the real command, since tests never touch real
# system paths.
# Usage:
#   setup_mock_bin
setup_mock_bin() {
    MOCK_BIN_DIRECTORY="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$MOCK_BIN_DIRECTORY"
    PATH="$MOCK_BIN_DIRECTORY:$PATH"
    create_mock sudo 'exec "$@"'
}

# Writes an executable mock command to the mock bin directory.
# Usage:
#   create_mock "command_name" 'shell body'
create_mock() {
    local name="$1"
    local body="$2"
    cat >"$MOCK_BIN_DIRECTORY/$name" <<SCRIPT
#!/usr/bin/env bash
$body
SCRIPT
    chmod +x "$MOCK_BIN_DIRECTORY/$name"
}

# Strips ANSI color escape codes from a string, since log_* functions color
# their output and tests should assert on message content, not styling.
# Usage:
#   strip_ansi "$output"
strip_ansi() {
    printf '%s' "$1" | sed -E $'s/\x1b\\[[0-9;]*m//g'
}

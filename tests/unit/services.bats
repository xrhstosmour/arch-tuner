#!/usr/bin/env bats

load test_helper/common

setup() {
    setup_mock_bin
    MOCK_STATE_DIRECTORY="$BATS_TEST_TMPDIR/systemctl-state"
    CALL_LOG="$BATS_TEST_TMPDIR/systemctl-calls.log"
    mkdir -p "$MOCK_STATE_DIRECTORY"
    : >"$CALL_LOG"
    create_mock systemctl '
state_directory="'"$MOCK_STATE_DIRECTORY"'"
echo "$*" >>"'"$CALL_LOG"'"
action="$1"
shift
service=""
for arg in "$@"; do
    case "$arg" in
    --*) ;;
    *) service="$arg" ;;
    esac
done
case "$action" in
is-active) [ -f "$state_directory/active-$service" ] && exit 0 || exit 1 ;;
is-enabled) [ -f "$state_directory/enabled-$service" ] && exit 0 || exit 1 ;;
enable) touch "$state_directory/enabled-$service" ;;
start) touch "$state_directory/active-$service" ;;
stop) rm -f "$state_directory/active-$service" ;;
esac
'
    # shellcheck disable=SC1091
    source "$FUNCTIONS_DIRECTORY/services.sh"
}

@test "is_service_active reports false for a service that was never started" {
    run is_service_active "example.service"
    [ "$output" = "false" ]
}

@test "is_service_active reports true once the service is marked active" {
    touch "$MOCK_STATE_DIRECTORY/active-example.service"
    run is_service_active "example.service"
    [ "$output" = "true" ]
}

@test "is_service_enabled reports true once the service is marked enabled" {
    touch "$MOCK_STATE_DIRECTORY/enabled-example.service"
    run is_service_enabled "example.service"
    [ "$output" = "true" ]
}

@test "enable_service enables a service that is not enabled yet" {
    enable_service "example.service" "" >/dev/null
    [ -f "$MOCK_STATE_DIRECTORY/enabled-example.service" ]
    grep -q '^enable example.service$' "$CALL_LOG"
}

@test "enable_service is a no-op when the service is already enabled" {
    touch "$MOCK_STATE_DIRECTORY/enabled-example.service"
    enable_service "example.service" "" >/dev/null
    ! grep -q '^enable ' "$CALL_LOG"
}

@test "start_service starts a service that is not active yet" {
    start_service "example.service" "" >/dev/null
    [ -f "$MOCK_STATE_DIRECTORY/active-example.service" ]
    grep -q '^start example.service$' "$CALL_LOG"
}

@test "start_service is a no-op when the service is already active" {
    touch "$MOCK_STATE_DIRECTORY/active-example.service"
    start_service "example.service" "" >/dev/null
    ! grep -q '^start ' "$CALL_LOG"
}

@test "stop_service stops a service that is currently active" {
    touch "$MOCK_STATE_DIRECTORY/active-example.service"
    stop_service "example.service" "" >/dev/null
    [ ! -f "$MOCK_STATE_DIRECTORY/active-example.service" ]
    grep -q '^stop example.service$' "$CALL_LOG"
}

@test "stop_service is a no-op when the service is already inactive" {
    stop_service "example.service" "" >/dev/null
    ! grep -q '^stop ' "$CALL_LOG"
}

@test "services default to system mode, not user mode" {
    run is_service_active "example.service"
    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
    ! grep -q -- '--user' "$CALL_LOG"
}

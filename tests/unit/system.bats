#!/usr/bin/env bats

load test_helper/common

# Only the process-management functions are unit tested here. update_system
# and reset_system_to_clean_state drive real pacman/chsh/reboot behavior and
# are exercised in the Docker integration harness instead.

setup() {
    setup_mock_bin
    export ARCH_TUNER_STATE_DIRECTORY="$BATS_TEST_TMPDIR/state"
    # shellcheck disable=SC1091
    source "$FUNCTIONS_DIRECTORY/system.sh"
}

@test "is_process_running reports false when no matching process exists" {
    run is_process_running "arch-tuner-nonexistent-process-marker"
    [ "$output" = "false" ]
}

@test "is_process_running reports true while a matching process is alive" {
    bash -c 'exec -a arch-tuner-test-proc-alive sleep 5' &
    local pid=$!
    sleep 0.2
    run is_process_running "arch-tuner-test-proc-alive"
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    [ "$output" = "true" ]
}

@test "stop_process terminates a matching running process" {
    bash -c 'exec -a arch-tuner-test-proc-stop sleep 30' &
    local pid=$!
    sleep 0.2
    stop_process "arch-tuner-test-proc-stop" "" >/dev/null
    sleep 0.2
    run is_process_running "arch-tuner-test-proc-stop"
    [ "$output" = "false" ]
}

@test "stop_process is a no-op when no matching process exists" {
    run stop_process "arch-tuner-nonexistent-process-marker" ""
    [ "$status" -eq 0 ]
}

@test "reboot_system does nothing when the flag is already 0" {
    run reboot_system 0 "SOME_FLAG"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

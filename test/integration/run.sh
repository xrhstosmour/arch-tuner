#!/usr/bin/env bash

# Builds the Arch Linux integration image and runs a helper, or install.sh,
# inside it under a real systemd PID 1, so changes can be observed against an
# actual Arch userland instead of only parsed by shellcheck.
# Usage:
#   test/integration/run.sh scripts/helpers/security/sysctl.sh
#   test/integration/run.sh install.sh

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE_NAME="arch-tuner-integration-test"
CONTAINER_NAME="arch-tuner-integration-test-$$"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path/to/helper.sh or install.sh>" >&2
    exit 1
fi

target="$1"

# Arch Linux only publishes an amd64 image, force that platform so this also
# works under emulation on an arm64 development machine.
docker build --platform=linux/amd64 -t "$IMAGE_NAME" -f "$REPOSITORY_ROOT/test/integration/Dockerfile" "$REPOSITORY_ROOT"

docker run -d --name "$CONTAINER_NAME" \
    --platform=linux/amd64 \
    --privileged \
    --cgroupns=host \
    --tmpfs /tmp --tmpfs /run --tmpfs /run/lock \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    "$IMAGE_NAME" >/dev/null

cleanup() {
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Wait for systemd to settle before running anything against it. "--wait"
# blocks until a terminal state is reached, "degraded" counts as booted, a
# container commonly has a unit or two that cannot succeed without real
# hardware, "starting" or a failed exec (daemon not ready yet) are retried.
system_state=""
for _ in $(seq 1 30); do
    system_state=$(docker exec "$CONTAINER_NAME" systemctl is-system-running --wait 2>/dev/null || true)
    case "$system_state" in
    running | degraded) break ;;
    esac
    sleep 1
done
case "$system_state" in
running | degraded) ;;
*)
    echo "systemd inside the container never finished booting (last state: '$system_state')" >&2
    docker logs "$CONTAINER_NAME" >&2 || true
    exit 1
    ;;
esac

docker exec -u tester "$CONTAINER_NAME" bash -c "cd /arch-tuner && sh '$target'"

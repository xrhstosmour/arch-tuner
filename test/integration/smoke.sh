#!/usr/bin/env bash

# Runs a curated set of container-friendly helpers twice each inside one
# booted Arch container, failing if a helper errors or a second, idempotent
# run reports making a change again. Helpers that touch real hardware, a
# bootloader, or the host's own kernel sysctl namespace are deliberately left
# out, they need real-host testing instead, see AGENTS.md.
# Usage:
#   test/integration/smoke.sh

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE_NAME="arch-tuner-integration-test"
CONTAINER_NAME="arch-tuner-integration-smoke-$$"

TARGETS=(
    "scripts/helpers/security/journald.sh"
    "scripts/helpers/security/automatic-updates.sh"
    "scripts/helpers/essentials/pacman.sh"
    "scripts/helpers/security/dns.sh"
)

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

# "degraded" counts as booted, a container commonly has a unit or two that
# cannot succeed without real hardware.
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

failures=0
for target in "${TARGETS[@]}"; do
    echo "=== $target: first run ==="
    if ! docker exec -u tester "$CONTAINER_NAME" bash -c "cd /arch-tuner && sh '$target'"; then
        echo "FAILED: $target (first run)" >&2
        failures=$((failures + 1))
        continue
    fi

    echo "=== $target: second run (idempotency check) ==="
    if ! docker exec -u tester "$CONTAINER_NAME" bash -c "cd /arch-tuner && sh '$target'"; then
        echo "FAILED: $target (second run)" >&2
        failures=$((failures + 1))
    fi
done

if [ "$failures" -gt 0 ]; then
    echo "$failures helper(s) failed" >&2
    exit 1
fi

echo "All helpers ran cleanly, twice."

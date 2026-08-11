#!/usr/bin/env bats

setup() {
    redis_script="$BATS_TEST_DIRNAME/../scripts/helpers/containers/redis.sh"
}

@test "redis.sh generates the password instead of hardcoding it" {
    ! grep -q 'known_values=.*REDIS_PASSWORD' "$redis_script"
    grep -q 'secret_keys=("REDIS_PASSWORD")' "$redis_script"
}

@test "redis.sh keeps maxmemory below the container's own cgroup memory limit" {
    # Regression guard: if maxmemory ever reaches or exceeds the container's
    # own 512M deploy.resources limit, the cgroup OOM-kills Redis before its
    # own eviction policy gets a chance to free memory.
    grep -q 'REDIS_MAXIMUM_MEMORY.*=.*384mb' "$redis_script"
}

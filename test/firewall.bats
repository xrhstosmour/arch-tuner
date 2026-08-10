#!/usr/bin/env bats

setup() {
    firewall_script="$BATS_TEST_DIRNAME/../scripts/helpers/security/firewall.sh"
}

@test "firewall.sh port checks are anchored, not a bare substring grep" {
    # Regression guard: an unanchored "grep -q '53/tcp'" would also match an
    # existing "8053/tcp" rule and wrongly skip adding the real one.
    ! grep -qE "grep -q '[0-9]+/(tcp|udp)'" "$firewall_script"
    grep -q "grep -qE '\^53/tcp" "$firewall_script"
}

@test "the anchored port pattern distinguishes 53/tcp from an unrelated 8053/tcp rule" {
    ufw_status='To                         Action      From
--                         ------      ----
8053/tcp                   ALLOW IN    Anywhere'

    ! echo "$ufw_status" | grep -qE '^53/tcp[[:space:]]'
}

@test "the anchored port pattern still matches the real rule when present" {
    ufw_status='To                         Action      From
--                         ------      ----
53/tcp                     ALLOW OUT   Anywhere'

    echo "$ufw_status" | grep -qE '^53/tcp[[:space:]]'
}

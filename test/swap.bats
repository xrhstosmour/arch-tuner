#!/usr/bin/env bats

@test "swap.sh adds the fstab entry needed to actually activate encrypted swap" {
    # Regression guard: a crypttab mapping alone only creates
    # /dev/mapper/swap, the ArchWiki dm-crypt/Swap encryption guide confirms
    # an fstab entry is what triggers swapon for it. Without one, the whole
    # feature was a no-op, a file and an unused crypttab line.
    swap_script="$BATS_TEST_DIRNAME/../scripts/helpers/privacy/swap.sh"

    grep -q '/etc/fstab' "$swap_script"
    grep -q '/dev/mapper/swap none swap' "$swap_script"
}

@test "swap.sh dedupes the fstab entry instead of appending it every run" {
    swap_script="$BATS_TEST_DIRNAME/../scripts/helpers/privacy/swap.sh"

    grep -q 'grep -qxF "\$FSTAB_ENTRY"' "$swap_script"
}

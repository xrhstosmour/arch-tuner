# Arch Tuner roadmap

An Arch Linux VPS hardening toolkit, three phases: essentials, privacy, security. See
`README.md` for what it does and `AGENTS.md` for how to work in this repository.

## Status

State management, pacman signature hardening, non-root user creation, SSH hardening, sudoers
hardening, fail2ban, kernel sysctl hardening, systemd and journald hardening, AIDE and auditd
integrity monitoring, automatic updates, firewall and DNS refinement, Docker engine hardening,
and essentials and usbguard trimming are merged to `main`. Every security helper is wired into
`security.sh`, and the hardening checklist in `README.md` reflects what actually runs.

A `bats` unit test harness (`test/`) and a Docker-based Arch Linux integration harness
(`test/integration/`) are merged, see `AGENTS.md`. `pacman.sh`, `aur.sh`, `dns.sh`, `memory.sh`,
and `nts.sh` now use the shared `change_configuration` function instead of ad-hoc `sed`/`grep`,
`shell.sh` uses `append_line_to_file` instead, and `firewall.sh` and `filesystem.sh` keep theirs
where neither helper's model fits. `aur.sh` cleans the pacman cache with `paccache` after
bootstrapping an AUR helper, and `reset_system_to_clean_state` removes packages that only existed
to support a pacman hook.

Encrypted swap (`privacy/swap.sh`), AppArmor Mandatory Access Control in complain mode
(`security/apparmor.sh`), and Secure Boot key creation (`security/secure-boot.sh`) are merged and
wired into `privacy.sh`/`security.sh`. Enrolling Secure Boot keys into firmware and signing the
bootloader and kernel stay a manual, administrator-reviewed step, see `AGENTS.md`, as does
enabling AppArmor's kernel `lsm=` parameter and enforcing any profile beyond complain mode.

## Remaining

- A Linux kernel runtime guard, once one exists with support for current kernels.

## Rejected

- A hardened kernel. Manual sysctl hardening stays on the stable default kernel instead, driver,
  language, virtualization, and process compatibility problems outweigh the benefit for a
  general-purpose VPS.
- PAM U2F/FIDO2 authentication for `sudo`. Needs a hardware authenticator physically attached to
  the machine, not available here, dropped rather than kept as a feature nobody can use or verify.

## Containers integration

Traefik, Authelia, and a self-hosted Netbird stack, from
`https://github.com/xrhstosmour/containers`, are now in scope. Traefik already exists there
(`networking/proxies/traefik`), Authelia and a self-hosted Netbird stack still need adding. Each
lands as its own future pull request, this repository only opens the firewall ports and documents
the prerequisites they need, see `documents/containers-integration.md`. This repository
standardizes on Netbird instead of Tailscale for VPN.

## Backlog

- `filebrowser` and `uptime-kuma` from the `xrhstosmour/containers` repository stay out of scope
  for now.

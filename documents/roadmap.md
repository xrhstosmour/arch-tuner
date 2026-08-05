# Arch Tuner roadmap

An Arch Linux VPS hardening toolkit, three phases: essentials, privacy, security. See
`README.md` for what it does and `AGENTS.md` for how to work in this repository.

## Status

State management, pacman signature hardening, non-root user creation, SSH hardening, sudoers
hardening, and fail2ban are merged to `main`.

A second wave is in review as pull requests #17 through #28: kernel sysctl hardening, systemd
and journald hardening, AIDE and auditd integrity monitoring, automatic updates, firewall and
DNS refinement, Docker engine hardening, essentials and usbguard trimming, and a final pull
request that wires every new helper into `security.sh` and documents the hardening checklist in
`README.md`. Once that series merges, a follow-up pull request should fold
`docs/implementation-plan.md` into this file and remove the old `docs/` directory, since
`documents/roadmap.md` is now the living plan.

## Remaining

- Encrypted swap, tracked as a `TODO` in `privacy.sh`.
- A Linux kernel runtime guard, once one exists with support for current kernels.
- Secure Boot.
- Pluggable Authentication Modules and a U2F/FIDO2 authenticator choice.
- Mandatory Access Control via AppArmor and its policies and profiles.

## Rejected

- A hardened kernel. Manual sysctl hardening stays on the stable default kernel instead, driver,
  language, virtualization, and process compatibility problems outweigh the benefit for a
  general-purpose VPS.

## Backlog

- Adopt the existing `change_configuration` function in `pacman.sh`, `aur.sh`, `dns.sh`,
  `memory.sh`, `firewall.sh`, `nts.sh`, `shell.sh`, and `filesystem.sh`, which still edit
  configuration files with ad-hoc `sed`/`grep` instead of the shared helper.
- Clean the AUR cache using `paccache` in `aur.sh`.
- Remove packages that are only used inside pacman hooks, tracked in `system.sh`.
- Integration with a future containers repository for application hosting. Traefik, filebrowser,
  uptime-kuma, and tailscale stay out of scope for this repository.

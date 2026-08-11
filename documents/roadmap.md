# Arch Tuner roadmap

An Arch Linux VPS hardening toolkit, four phases: essentials, privacy, security, containers. See
`README.md` for what it does and `AGENTS.md` for how to work in this repository.

## Status

State management, pacman signature hardening, non-root user creation, SSH hardening, sudoers
hardening, fail2ban, kernel sysctl hardening, systemd and journald hardening, AIDE and auditd
integrity monitoring, automatic updates, firewall and DNS refinement, Docker engine hardening,
and essentials and usbguard trimming are merged to `main`. Every security helper is wired into
`security.sh`, and the hardening checklist in `README.md` reflects what actually runs.

A `bats` unit test harness (`test/`) and a Docker-based Arch Linux integration harness
(`test/integration/`) are merged, see `AGENTS.md`. `pacman.sh`, `aur.sh`, `dns.sh`, `memory.sh`, `nts.sh`,
and `umask.sh` now use the shared `change_configuration` function instead of ad-hoc `sed`/`grep`,
`shell.sh` uses `append_line_to_file` instead, and `firewall.sh` and `filesystem.sh` keep theirs
where neither helper's model fits. `umask.sh` migrated its `/etc/profile` and `/etc/bash.bashrc` cases
to `change_configuration`, but keeps a raw `sed -i` replace for `/etc/login.defs`, whose `UMASK` key is
tab-separated from its value in the real file, `change_configuration` only matches a literal separator
baked into the key, so it cannot find that line. `reset_system_to_clean_state` in `system.sh` also keeps
a raw `sed -i` line deletion for the hardened memory allocator configuration, `change_configuration`
only sets a key's value, it does not delete a line, so no migration applies there. `aur.sh` cleans
the pacman cache with `paccache` after bootstrapping an AUR helper, and `reset_system_to_clean_state`
removes packages that only existed to support a pacman hook.

Encrypted swap (`privacy/swap.sh`), AppArmor Mandatory Access Control in complain mode
(`security/apparmor.sh`), and Secure Boot key creation (`security/secure-boot.sh`) are merged and
wired into `privacy.sh`/`security.sh`. Enrolling Secure Boot keys into firmware and signing the
bootloader and kernel stay a manual, administrator-reviewed step, see `AGENTS.md`, as does
enabling AppArmor's kernel `lsm=` parameter and enforcing any profile beyond complain mode.

A fourth phase, `containers`, deploys Docker Compose stacks from the pinned upstream
`xrhstosmour/containers` repository, one stack per pull request, each verified working with a
real `docker compose` run before it opens, not just read for review. Unlike the other three
phases it never marks itself complete, since new stacks land over time. 5 pull requests are open
against this phase, stacked in this order, each depending on the one before it: the scaffold
(`scripts/utilities/containers.sh`, `scripts/helpers/functions/containers.sh`, the pinned
checkout at `/opt/arch-tuner/containers`), a shared PostgreSQL/Redis pair, Traefik with ACME
HTTP-01, Authelia fronted through Traefik, and NetBird registered as a public OpenID Connect
client of Authelia instead of a third-party identity provider. NetBird's own
dashboard/signal/relay/management stay on their own ports rather than fronted through Traefik,
its documented reverse-proxy support needs a dedicated TLS-passthrough component this pinned
upstream commit does not ship. `coturn`'s TURN relay ports stay open for the same reason, they
cannot be reverse-proxied. Filestash, Uptime Kuma, LinkStack, and Dockhand remain, each fronted
by Traefik.

## Remaining

- A Linux kernel runtime guard, once one exists with support for current kernels.

## Rejected

- A hardened kernel. Manual sysctl hardening stays on the stable default kernel instead, driver,
  language, virtualization, and process compatibility problems outweigh the benefit for a
  general-purpose VPS.
- PAM U2F/FIDO2 authentication for `sudo`. Needs a hardware authenticator physically attached to
  the machine, not available here, dropped rather than kept as a feature nobody can use or verify.

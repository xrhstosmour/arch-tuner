# Arch Tuner Implementation Plan

## Purpose

The Arch Tuner repository prepares an Arch Linux server VPS by implementing a comprehensive hardening toolkit. It includes package management configuration, security hardening measures, privacy protections, and CI validation to ensure every change is checked via PR. This repo focuses exclusively on server hardening and prepares the host environment (including Docker engine) for container applications that will live in a separate containers repo. The implementation follows a three-phase approach (essentials, privacy, security) with careful state management and parallel-safe development practices.

## Architecture

The implementation follows a hierarchical structure starting with `install.sh` which drives three main phases: essentials, privacy, and security. Each phase is implemented in `scripts/utilities/` as corresponding shell scripts that orchestrate helper functions. The architecture includes:

- **Phase 1 (Essentials)**: `scripts/utilities/essentials.sh` → `scripts/helpers/essentials/` → `scripts/packages/essentials/` package lists and `scripts/configurations/essentials/` config payloads
- **Phase 2 (Privacy)**: `scripts/utilities/privacy.sh` → `scripts/helpers/privacy/` → `scripts/helpers/functions/` shared utilities
- **Phase 3 (Security)**: `scripts/utilities/security.sh` → `scripts/helpers/security/` → `scripts/configurations/security/` config payloads

Runtime flags are managed through `/var/lib/arch-tuner/state.sh` (PR 2). The system sources state flags that override defaults from `scripts/core/flags.sh` and `scripts/core/constants.sh`. CI includes comprehensive validation with `shellcheck -x -S warning`, `bash -n` checks, `gitleaks` for secrets detection, and `markdownlint` for documentation quality.

## Agent Operating Guidelines

### Branching and Workflow

- Always branch from latest origin/main: `git fetch origin && git checkout -b <branch> origin/main`. Never branch from stale local main.
- One PR per task. Do NOT open or merge PRs; the coordinator handles this.
- Run ALL verification commands and paste exact outputs and exit codes. Never claim a check passed without running it and seeing exit 0. This is a hard requirement.
- **Critical verification commands** (all must exit 0):
  - `find scripts -name '*.sh' -type f -print0 | xargs -0 shellcheck -x -S warning`
  - `shellcheck -x -S warning install.sh`
  - `find scripts -name '*.sh' -type f -exec bash -n {} \;`
  - `bash -n install.sh`
  - `python3 -c "import json; json.load(open('.markdownlint.json'))"` and YAML parse for .pre-commit-config.yaml
  - `grep -rn "keyboard\|kloak" scripts/ || true` (no hits)
  - `git status --short` clean after push.

### Code Standards

- Follow existing patterns: read neighboring helpers first; reuse scripts/helpers/functions/*
- Use single whole words for names (no abbreviations like `docs`, `config`, `ref`, `err`, `msg`, `max`, `min`, `idx`, `cnt`, `btn`, `tmp`, `prev`)
- Comments above code ending with a period
- Package lists: plain text, one package per line, in scripts/packages/security/*.txt (matching format of scripts/packages/essentials/terminal.txt)
- Config payloads: scripts/configurations/security/<feature>/; bash payload scripts need #!/bin/bash; fish payloads MUST use .fish extension (learned in PR 1)
- **PARALLEL-SAFETY RULE**: Hardening PRs add their own new helper file(s), configs, and package lists and MUST NOT modify scripts/utilities/security.sh, scripts/core/*, or shared files under scripts/helpers/functions/. All wiring of new helpers into scripts/utilities/security.sh happens only in PR 13.

### Commits and Pushes

- Small logical commits, imperative present tense, no emojis, sign if possible else --no-gpg-sign
- Push the branch; confirm `git fetch origin && git log --oneline origin/<branch>..HEAD` is empty
- Report: files changed, verification outputs, commit SHAs, push confirmation

## PR Series

### PR 2 `refactor/runtime-state-file`

**Status:** In progress

**Files to create/modify:**
- `scripts/helpers/functions/state.sh`
- `scripts/helpers/functions/strings.sh` (remove the OLD change_flag_value function; the new one lives in state.sh, while strings.sh keeps its other string helpers)

**Changes:**
- Introduce new state mechanism with STATE_DIRECTORY defaulting to `/var/lib/arch-tuner/state.sh`
- Add ARCH_TUNER_STATE_DIRECTORY environment variable for testing
- Implement `change_flag_value <flag> <value>` writing to state.sh via temp+mv
- Implement `source_state()` to source state overrides defaults
- Implement `reset_state()` for clean state
- Update all call sites in `scripts/helpers/functions/system.sh`
- Convert `flags.sh` to documented defaults only (keep the same filename, no rename)
- Keep `constants.sh` for static values only
- Ensure runtime AUR_PACKAGE_MANAGER moves to state
- Sourcing order: constants.sh and flags.sh defaults are sourced first, then state.sh, so runtime values override defaults

**Acceptance Criteria:**
- State file correctly stores and retrieves flag values
- State overrides default values from flags.sh and constants.sh
- All existing flag modification operations work correctly with state
- System reset properly removes state file
- Testing with ARCH_TUNER_STATE_DIRECTORY override works as expected

### PR 3 `security/pacman-hardening`

**Files to create/modify:**
- `scripts/helpers/essentials/pacman.sh` (modified)
- `scripts/helpers/essentials/aur.sh` (modified)
- `scripts/packages/security/pacman.txt` (new)

**Changes:**
- Modify `pacman.sh`: Ensure `SigLevel = Required TrustedOnly` and `RepoSigLevel = Required` in `/etc/pacman.conf` and keep existing Color, ParallelDownloads, and paccache configuration
- Modify `aur.sh`: Add `CleanMethod = KeepInstalled` to AUR helper config if applicable
- Create new `scripts/packages/security/pacman.txt` with `pacman-contrib` package

**Acceptance Criteria:**
- Pacman configuration hardened with proper signature verification
- AUR helper configured to keep installed packages during cleanup
- Package list correctly installed
- No regression in existing pacman functionality

### PR 4 `security/user-ssh-hardening`

**Files to create/modify:**
- `scripts/helpers/security/user.sh` (new)
- `scripts/helpers/security/ssh.sh` (new)
- `scripts/packages/security/ssh.txt` (new)
- `scripts/configurations/security/ssh/sshd_config` (new)

**Changes:**
- Create `user.sh`: Implement non-root admin user creation in wheel group with sudo access
- Create `ssh.sh`: Configure SSH server with secure defaults and key-based authentication
- Create `ssh.txt`: List `openssh` package
- Create `sshd_config`: Set `PermitRootLogin no`, `PasswordAuthentication no`, `PubkeyAuthentication yes`, `Port 2222`, `MaxAuthTries 3`, `ClientAliveInterval 300`, `ClientAliveCountMax 2`, `AuthenticationMethods publickey`, `UsePAM yes`, `X11Forwarding no`

**Acceptance Criteria:**
- Non-root admin user created with proper sudo privileges
- SSH server hardened with security best practices
- SSH service starts and runs correctly
- Key-based authentication works as expected

### PR 5 `security/sudoers-fail2ban`

**Files to create/modify:**
- `scripts/helpers/security/sudoers.sh` (new)
- `scripts/configurations/security/sudoers/99-hardening` (new)
- `scripts/helpers/security/fail2ban.sh` (new)
- `scripts/configurations/security/fail2ban/jail.local` (new)
- `scripts/packages/security/fail2ban.txt` (new)

**Changes:**
- Create `sudoers.sh`: Configure sudoers file with security hardening
- Create `99-hardening`: Add `Defaults requiretty`, `log_input`, `log_output`, `passwd_tries=3`, `timestamp_timeout=5`
- Create `fail2ban.sh`: Install and configure fail2ban service
- Create `jail.local`: Configure sshd jail with `bantime 1h`, `findtime 10m`, `maxretry 3`, `ignoreip 127.0.0.1/8 ::1`
- Create `fail2ban.txt`: List `fail2ban` package

**Acceptance Criteria:**
- Sudoers file hardened with security settings
- Fail2ban service installed and configured
- SSH brute-force protection active
- Logs properly captured for security auditing

### PR 6 `security/sysctl-hardening`

**Files to create/modify:**
- `scripts/helpers/security/sysctl.sh` (new)
- `scripts/configurations/security/sysctl/99-hardening.conf` (new)
- `scripts/packages/security/sysctl.txt` (new)

**Changes:**
- Create `sysctl.sh`: Apply kernel sysctl hardening settings
- Create `99-hardening.conf`: Set `kernel.kptr_restrict=2`, `kernel.unprivileged_bpf_disabled=1`, `kernel.yama.ptrace_scope=2`, `kernel.sysrq=0`, `fs.protected_hardlinks=1`, `fs.protected_symlinks=1`, `fs.suid_dumpable=0`, `net.ipv4.tcp_syncookies=1`, `net.ipv4.conf.all.rp_filter=1`, `net.ipv4.conf.default.rp_filter=1`, `net.ipv4.conf.all.accept_redirects=0`, `net.ipv4.conf.default.accept_redirects=0`, `net.ipv6.conf.all.accept_redirects=0`, `net.ipv6.conf.default.accept_redirects=0`, `net.ipv4.conf.all.send_redirects=0`, `net.ipv4.conf.default.send_redirects=0`, `vm.mmap_rnd_bits=32`, `vm.mmap_rnd_compat_bits=16`, `kernel.dmesg_restrict=1`
- Create `sysctl.txt`: No packages needed, just kernel settings

**Acceptance Criteria:**
- Kernel parameters hardened according to security best practices
- Settings persist across reboots
- No system instability from overly restrictive settings

### PR 7 `security/systemd-journald`

**Files to create/modify:**
- `scripts/helpers/security/systemd.sh` (new)
- `scripts/configurations/security/systemd/99-hardening` (new)
- `scripts/helpers/security/journald.sh` (new)
- `scripts/configurations/security/journald/99-hardening.conf` (new)

**Changes:**
- Create `systemd.sh`: Configure systemd services with security hardening (PrivateTmp, ProtectSystem=strict, ProtectHome=yes, NoNewPrivileges=yes, ProtectKernelTunables, ProtectKernelModules, ProtectControlGroups, RestrictAddressFamilies, RestrictNamespaces, LockPersonality, MemoryDenyWriteExecute, RestrictRealtime, RestrictSUIDSGID, RemoveIPC)
- Create `99-hardening`: Drop-in units for sshd, chronyd, docker with above settings
- Create `journald.sh`: Configure systemd journald service
- Create `99-hardening.conf`: Set `Storage=persistent`, `Compress=yes`, `SystemMaxUse=500M`, `MaxRetentionSec=30day`, `RateLimitIntervalSec=30s`, `RateLimitBurst=10000`, `ForwardToSyslog=no`, `ForwardToWall=no`

**Acceptance Criteria:**
- Systemd services hardened with security drop-ins
- Journald configured with proper log retention and privacy
- Services start and run correctly with new settings
- Logs written to persistent storage

### PR 8 `security/integrity-monitoring`

**Files to create/modify:**
- `scripts/helpers/security/aide.sh` (new)
- `scripts/configurations/security/aide/aide.conf` (new)
- `scripts/packages/security/aide.txt` (new)
- `scripts/helpers/security/auditd.sh` (new)
- `scripts/configurations/security/auditd/rules.d/*.rules` (new)
- `scripts/packages/security/auditd.txt` (new)

**Changes:**
- Create `aide.sh`: Install and configure AIDE integrity monitoring
- Create `aide.conf`: Basic AIDE configuration for file integrity checks
- Create `aide.txt`: List `aide` package
- Create `auditd.sh`: Install and configure audit daemon
- Create rules: Basic auth, file access, privilege escalation rules
- Create `auditd.txt`: List `audit` package
- Configure augenrules to load audit rules

**Acceptance Criteria:**
- AIDE installed and configured to monitor critical system files
- Audit daemon installed with basic security rules
- Integrity monitoring active and running
- Audit logs capturing security events

### PR 9 `security/automatic-updates`

**Files to create/modify:**
- `scripts/helpers/security/automatic-updates.sh` (new)
- `scripts/packages/security/automatic-updates.txt` (new)
- `systemd/arch-tuner-update.service` (new)
- `systemd/arch-tuner-update.timer` (new)

**Changes:**
- Create `automatic-updates.sh`: Install `pacman-contrib` package
- Create `automatic-updates.txt`: List `pacman-contrib` package
- Create systemd service unit: Runs `pacman -Syu --noconfirm` daily
- Create systemd timer: Triggers service daily
- Logs output to journald

**Acceptance Criteria:**
- Automatic updates configured via systemd timer
- System updates daily without human intervention
- Updates logged to journald for auditing
- No excessive resource usage

### PR 10 `security/refine-existing`

**Files to create/modify:**
- `scripts/helpers/security/firewall.sh` (modified)
- `scripts/helpers/security/dns.sh` (modified)
- `scripts/helpers/security/mount.sh` (modified)
- `scripts/helpers/security/ids.sh` (modified)
- `scripts/helpers/security/antivirus.sh` (modified)

**Changes:**
- Modify `firewall.sh`: Server-only implementation (allow SSH port, deny everything else, IPv6 support)
- Modify `dns.sh`: Set `DNSOverTLS=yes` in `/etc/systemd/resolved.conf`
- Modify `mount.sh`: Add `/tmp` mount with `nodev,nosuid,noexec`, `/var/tmp` similar settings
- Modify `ids.sh`: Add pacman hook to re-run SUID/SGID stripping after updates
- Modify `antivirus.sh`: Add daily scan systemd timer

**Acceptance Criteria:**
- Firewall hardened for server environment
- DNSSEC and DNSOverTLS enabled
- Mount points secured with proper permissions
- ID management enhanced with post-update security
- Antivirus configured for regular scanning

### PR 11 `security/docker-engine`

**Files to create/modify:**
- `scripts/helpers/security/docker-engine.sh` (modified)
- `scripts/configurations/security/docker/daemon.json` (modified)
- `scripts/packages/security/docker.txt` (new)

**Changes:**
- Modify `docker-engine.sh`: Update Docker engine configuration
- Modify `daemon.json`: Add `userns-remap=default`, `live-restore=true`, `no-new-privileges=true`, `icc=false`; keep `log-driver: json-file`, `max-size: 10m`, `max-file: 3`
- Create `docker.txt`: List `docker`, `docker-compose` packages
- Note: `userns-remap` needs subordinate uid/gid ranges on host

**Acceptance Criteria:**
- Docker engine hardened with security features
- Configuration persists across reboots
- Docker service starts and runs correctly
- Subordinate uid/gid ranges configured if needed

### PR 12 `privacy/server-privacy-cleanup`

**Files to create/modify:**
- `scripts/helpers/privacy/network.sh` (modified)

**Changes:**
- Modify `network.sh`: Remove NetworkManager MAC randomization (desktop-only), keep umask 077 from `umask.sh` unchanged

**Acceptance Criteria:**
- MAC randomization removed from server network configuration
- Privacy hardening preserved for server environment
- No regression in existing functionality

### PR 13 `chore/wire-up-and-docs`

**Files to create/modify:**
- `scripts/utilities/security.sh` (modified)
- `README.md` (updated)

**Changes:**
- Modify `security.sh`: Call ALL new helpers in a sane order after existing ones (user, ssh, sudoers, fail2ban, sysctl, systemd, journald, aide, auditd, automatic-updates, docker-engine)
- Update README: Add hardening checklist and usage documentation
- Ensure all CI checks pass repo-wide

**Acceptance Criteria:**
- All security helpers properly wired and executed
- Documentation updated for end users
- CI validation passes all checks
- System can be installed and hardened end-to-end

## Verification command block

All verification commands (exact commands, must exit 0):

```bash
find scripts -name '*.sh' -type f -print0 | xargs -0 shellcheck -x -S warning
shellcheck -x -S warning install.sh
find scripts -name '*.sh' -type f -exec bash -n {} \;
bash -n install.sh
python3 -c "import json; json.load(open('.markdownlint.json'))" && python3 -c "import yaml; yaml.safe_load(open('.pre-commit-config.yaml'))"
grep -rn "keyboard\|kloak" scripts/ || true
git status --short
git fetch origin && git log --oneline origin/<branch>..HEAD
```

## Coordination note

The coordinator opens each PR, waits for CI (all 4 jobs), has it reviewed, merges with `gh pr merge --merge`. Each PR must be independently mergeable.

# Agent guide

Tips and rules for any AI agent working in this repository. Read this first.

## What this repository is

Arch Tuner is an Arch Linux VPS hardening toolkit. `install.sh` drives three phases in order:

- `scripts/utilities/essentials.sh`: package manager configuration, essential packages, shell setup.
- `scripts/utilities/privacy.sh`: privacy-hardening helpers under `scripts/helpers/privacy/`.
- `scripts/utilities/security.sh`: security-hardening helpers under `scripts/helpers/security/`.

`documents/roadmap.md` is the living plan, what phases exist, what the current pull request
series adds, and what remains. Read it before picking up work.

## Architecture

- `scripts/core/`: `constants.sh` for static values, `flags.sh` for documented defaults. Both are
  sourced before the runtime state file, so runtime values can override them.
- `scripts/helpers/functions/`: shared utilities every helper sources, see below.
- `scripts/helpers/essentials/`, `scripts/helpers/privacy/`, `scripts/helpers/security/`: one file
  per feature, called from the matching `scripts/utilities/*.sh`.
- `scripts/configurations/<phase>/<feature>/`: config payloads a helper copies onto the host.
  Bash payloads need `#!/bin/bash`. Fish payloads use the `.fish` extension.
- `scripts/packages/<phase>/<feature>.txt`: plain text, one package per line.
- `systemd/`: standalone unit files a helper deploys to `/etc/systemd/system/`, for units that
  don't fit the drop-in pattern.

## Runtime state and local testing

- Runtime state lives in `/var/lib/arch-tuner/state.sh`, written by `change_flag_value` in
  `scripts/helpers/functions/state.sh` and sourced by `source_state` after `constants.sh` and
  `flags.sh`, so it overrides their defaults. `reset_state` deletes it.
- Set `ARCH_TUNER_STATE_DIRECTORY` to point the state file somewhere else for testing, so a local
  run never touches `/var/lib/arch-tuner` on your machine:
  `ARCH_TUNER_STATE_DIRECTORY=/tmp/arch-tuner-test sh scripts/helpers/security/sysctl.sh`.
- Run a single helper directly with `sh scripts/helpers/security/<name>.sh` instead of the whole
  `install.sh` flow, most helpers only need their own config and package list to do anything
  useful. `install.sh` itself reboots between the essentials and privacy phases, so it is not
  meant to be re-run repeatedly while iterating on one helper.
- Every helper is idempotent through `compare_files` or `are_packages_installed`, safe to run
  more than once, a second run should report no changes and skip service restarts.

## Shared helper functions

Source `scripts/helpers/functions/*.sh` for these instead of writing a new equivalent:

- `compare_files "target" "source"`: `true`/`false` string, whether two files are identical.
  Pair it with a changes-made flag so a restart only happens when something actually changed.
- `change_configuration "key" "value" "file"`: edit a single key in place in a config file.
  Several helpers still use ad-hoc `sed`/`grep` instead, see `documents/roadmap.md` backlog.
- `install_packages "packages_or_file" "package_manager" "message"` and
  `are_packages_installed "packages_or_file" "package_manager"`: accept either a space-separated
  string or a path to a `scripts/packages/**/*.txt` file.
- `enable_service`, `start_service`, `stop_service`, `is_service_active`, `is_service_enabled`:
  systemd unit lifecycle, each takes a unit name and an optional log message.
- `log_info`, `log_success`, `log_warning`, `log_error`: colored output, `-n` suppresses the
  leading newline.
- `is_file_contained_in_another "file" "fragment_file"`: whether a fragment already appears in a
  larger file, used before appending shell abbreviations or config blocks.
- `ask_user_before_execution "message" "disable_logs" "target" "arguments"` and
  `prompt_user_input "message" "default"`: interactive prompts, only used from `install.sh` and
  interactive helpers like `user.sh`, never from a helper that should run unattended.

## Merge workflow

- Never push directly to `main`. Every change goes through a pull request.
- CI must be green before merge. `.github/workflows/ci.yml` runs `shellcheck`, `bash-syntax`,
  `gitleaks`, and `markdownlint`. Fix on the branch and push, never merge around a red check.
- Merge with `gh pr merge <number> --merge --delete-branch`.
- Force-push is fine on feature branches with `--force-with-lease`, never on `main`.
- Keep pull requests single-topic, non-stacked, and independently mergeable against `main`.

## Parallel-safety rule

When multiple pull requests add hardening helpers in parallel, each adds its own new helper
file, configuration, and package list, and must not modify `scripts/utilities/security.sh`,
`scripts/core/*`, or shared files under `scripts/helpers/functions/`. Wiring a new helper into
`security.sh` happens in a dedicated wiring pull request, after the helper pull requests merge.

## Naming and style

- Use single whole words for variables, functions, files, and folders. Never abbreviate a
  regular word: `documents` not `docs`, `configuration` not `config`, `reference` not `ref`,
  `temporary` not `tmp`, `previous` not `prev`, `error` not `err`, `message` not `msg`,
  `maximum`/`minimum` not `max`/`min`, `index`/`count` not `idx`/`cnt`. Common acronyms like
  `ID`, `URL`, `API`, `HTTP`, `SSH`, and `DNS` are fine.
- Comments end with a period and sit above the code they describe.

## Commits and pull requests

- Commits are single-line, imperative, present tense, one topic per commit, with technical
  identifiers in backticks such as `` `sysctl` `` or `` `daemon.json` ``. No type prefixes like
  `fix:` or `feat:`, no co-authors, no trailing punctuation. Target around 100 lines per commit.
- Pull request titles are short, descriptive, no type prefixes, under 60 characters.
- Pull request bodies use a **What** and **Why** structure. Omit a testing section, there is
  nothing to manually exercise in shell hardening scripts beyond what CI already runs.
- Assign the author to every pull request. Apply a label only if it already exists in the
  repository and appears on at least two of the author's last ten pull requests. Never create a
  new label.
- Communication is compact and direct. No em dashes, no semicolons, no emojis, no decorative
  dividers, and commas instead of parenthetical asides.

## Verification

Run before every push, all must exit 0.

```bash
find scripts -name '*.sh' -type f -print0 | xargs -0 shellcheck -x -S warning
shellcheck -x -S warning install.sh
find scripts -name '*.sh' -type f -exec bash -n {} \;
bash -n install.sh
markdownlint README.md --config .markdownlint.json
grep -rn "keyboard\|kloak" scripts/ || true
bats test/
```

## Security

- This is a hardening toolkit. Never weaken a default, such as a wider firewall rule or a
  disabled check, without a comment explaining why the server needs it.
- Never commit secrets, tokens, or credentials. `gitleaks` runs in CI, but check before pushing.
- The kernel stays on the stable default. A hardened kernel is deliberately rejected in
  `scripts/utilities/security.sh` because it causes driver, language, and virtualization
  compatibility problems, and the performance loss outweighs the benefit for a general-purpose
  VPS.

## Known gotchas

- A generic `systemd` sandboxing drop-in, `ProtectSystem=strict`, `RestrictNamespaces`,
  `NoNewPrivileges`, and similar, breaks `docker.service`. Docker needs namespace and cgroup
  manipulation and kernel module loading that these directives block. Harden Docker through
  `daemon.json` instead, see `docker-engine.sh`.
- `fail2ban`'s `sshd` jail resolves its ban target through the `ssh` service name by default,
  which means port 22. If `sshd_config` moves SSH to a different port, `jail.local` needs a
  matching `port` override under `[sshd]` or bans silently miss the real port.
- `grub-mkconfig` is not guaranteed to exist. Some Arch VPS images use `systemd-boot`, `extlinux`,
  or a provider-managed kernel and initrd outside the guest. Guard any bootloader-specific call
  behind a check for the command and its expected directory before running it under `set -e`.
- A helper that unconditionally stops a service near the top of the script must also
  unconditionally start and enable it at the end, not only when a change-made flag is set,
  otherwise an idempotent rerun with no config drift leaves the service stopped.
- Commit signing through 1Password's SSH agent can fail transiently with
  `1Password: failed to fill whole buffer`, often because a Touch ID or Apple Watch approval
  prompt is waiting and unreachable from a non-interactive shell. Retry once the owner unlocks
  1Password, do not fall back to `--no-gpg-sign` without asking first.

# Arch Server Hardening Toolkit

An Arch Linux server hardening toolkit for securing a VPS, a cloud instance, or bare metal across three phases: essentials, privacy, and security. It evolved from an Arch desktop post-install toolkit; desktop-only components like display managers and desktop environments have since been removed to keep it lean and server-focused.

See [`AGENTS.md`](AGENTS.md) if you are an agent.

## Installation

To use the toolkit:

1. Clone the repository:

   ```bash
   git clone https://github.com/xrhstosmour/arch-tuner.git
   cd arch-tuner
   ```

2. Review the scripts and configuration files as needed.

3. Run the installer:

   ```bash
   sudo ./install.sh
   ```

   or without sudo if you have appropriate permissions:

   ```bash
   ./install.sh
   ```

### Quick Install

`bootstrap.sh` clones the repository into a temporary directory and runs the installer for you,
skipping the manual clone step above:

```bash
curl -fsSL https://raw.githubusercontent.com/xrhstosmour/arch-tuner/main/bootstrap.sh | sudo bash
```

This is a hardening toolkit that runs with root privileges, review the cloned steps above first
if you would rather read the scripts before running them. `bootstrap.sh` itself is short enough to
audit in seconds, unlike the rest of the repository it goes on to fetch and run.

The installer runs in three phases:

- **Essentials**: Core system setup including package manager configuration, essential packages, and basic system utilities
- **Privacy**: System hardening for privacy, including secure networking configurations and privacy-enhancing tools
- **Security**: Comprehensive security hardening including firewall, antivirus, DNSSEC, and system hardening measures

The installer asks for confirmation before each phase and reboots between phases. Runtime state is stored in `/var/lib/arch-tuner/state.sh` and can be overridden with `ARCH_TUNER_STATE_DIRECTORY` environment variable for testing purposes.

## Hardening Checklist

The toolkit implements the following hardening measures:

- Pacman signature verification
- Non-root administrative user creation
- SSH key-only authentication on port 2222
- Sudoers hardening
- Fail2ban installation and configuration
- Kernel sysctl hardening
- Systemd service hardening and journald log retention
- AIDE integrity monitoring
- Audit daemon configuration
- Automatic daily system updates
- Docker engine hardening: user namespaces, no new privileges, ICC off
- Firewall denying incoming connections except SSH 2222
- DNS over TLS
- Mount points hardening
- SUID/SGID stripping with pacman hook
- Antivirus with daily scan timer
- Encrypted swap with a random, never-persisted per-boot key
- AppArmor Mandatory Access Control, complain mode by default
- Secure Boot key creation, enrollment and signing stay manual, see `AGENTS.md`

## Contributing

Contributions are welcome. See [`AGENTS.md`](AGENTS.md) for repository conventions and the merge
workflow.

## License

MIT License. See `LICENSE` file for details.

# Arch Server Hardening Toolkit

An Arch Linux server hardening toolkit for securing and hardening your Arch-based server, whether a VPS, a cloud instance, or bare metal. Originally evolved from an Arch desktop post-install toolkit, this project is now focused exclusively on server hardening.

See [`AGENTS.md`](AGENTS.md) if you are an agent.

## Why Server-Only

This toolkit is purpose-built for Arch server deployments, whether a VPS, a cloud instance, or bare metal, focusing on essential security hardening, privacy protection, and system essentials. Features that were relevant for desktop systems have been removed to keep the toolkit lean and secure for server environments.

Desktop-specific components like display managers, graphical login interfaces, and desktop environments have all been removed.

## What It Includes

- **Essentials Phase**: Core system setup including package manager configuration, essential packages, and basic system utilities
- **Privacy Phase**: System hardening for privacy, including secure networking configurations and privacy-enhancing tools
- **Security Phase**: Comprehensive security hardening including firewall, antivirus, DNSSEC, and system hardening measures

## Future Plans

This toolkit is prepared to integrate with a future containers repository that will manage container applications. For now, container applications like filebrowser, uptime-kuma, traefik, and tailscale are intentionally out of scope here.

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
- Optional PAM U2F/FIDO2 authentication for sudo, needs a hardware key
- AppArmor Mandatory Access Control, complain mode by default
- Secure Boot key creation, enrollment and signing stay manual, see `AGENTS.md`

## Roadmap

See [`documents/roadmap.md`](documents/roadmap.md) for what is merged, what is in review, and
what remains.

## Contributing

Contributions are welcome. See [`AGENTS.md`](AGENTS.md) for repository conventions and the merge
workflow.

## License

MIT License. See `LICENSE` file for details.

## Links

- [Arch Wiki](https://wiki.archlinux.org/)
- [Arch Linux Documentation](https://wiki.archlinux.org/index.php/Main_page)

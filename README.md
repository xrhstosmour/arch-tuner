# Arch VPS Hardening Toolkit

An Arch Linux VPS hardening toolkit for securing and hardening your Arch-based Virtual Private Server. Originally evolved from an Arch desktop post-install toolkit, this project is now focused exclusively on server hardening.

See [`AGENTS.md`](AGENTS.md) if you are an agent.

## Why Server-Only

This toolkit is purpose-built for Arch VPS deployments, focusing on essential security hardening, privacy protection, and system essentials. Features that were relevant for desktop systems have been removed to keep the toolkit lean and secure for server environments.

Desktop-specific components like display managers, graphical login interfaces, and desktop environments have all been removed.

## What It Includes

- **Essentials Phase**: Core system setup including package manager configuration, essential packages, and basic system utilities
- **Privacy Phase**: System hardening for privacy, including secure networking configurations and privacy-enhancing tools
- **Security Phase**: Comprehensive security hardening including firewall, antivirus, DNSSEC, and system hardening measures

## Future Plans

This toolkit is prepared to integrate with a future containers repository that will manage container applications. For now, container applications like filebrowser, uptime-kuma, traefik, and tailscale are intentionally out of scope here.

## Installation

See the project documentation for detailed installation instructions.

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

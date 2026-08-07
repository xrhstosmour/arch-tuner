# Containers integration prep

Planning note for wiring `https://github.com/xrhstosmour/containers` Docker Compose services onto
a host this toolkit has hardened. This repository does not install any container, each service
lands as its own future pull request against that repository. See `documents/roadmap.md` for how
this fits the overall plan.

## Prerequisite

The containers repository's own `README.md` requires a shared Docker network before starting any
service:

```bash
docker network create internal
```

Run this once per host before starting any container from that repository.

## Port matrix already open on this host

All the ports below are inbound, opened by `security/firewall.sh` except the SSH port, which is
opened by `security/ssh.sh`:

- A custom SSH port, chosen at install time, never the default 22.
- `80/tcp`: Traefik, HTTP redirect to HTTPS.
- `443/tcp`: Traefik, HTTPS, fronts Netbird and Authelia.
- `3478/udp`: Netbird's Coturn STUN/TURN, cannot be proxied.

Authelia gets no separate inbound port, it's only reachable through Traefik on `443/tcp`.

## Upcoming pull requests

- [ ] Wire Traefik (`networking/proxies/traefik`, already in the containers repository) as the
      reverse proxy in front of Authelia and Netbird.
- [ ] Add Authelia to the containers repository, routed through Traefik.
- [ ] Add a self-hosted Netbird stack (management, signal, relay, Coturn) to the containers
      repository, routed through Traefik per its recommended reverse-proxy architecture.

Each of these is scoped and merged independently.

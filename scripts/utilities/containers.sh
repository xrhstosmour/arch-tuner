#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
CONTAINERS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions and flags.
source "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/functions/packages.sh"
source "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/functions/services.sh"
source "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/functions/containers.sh"
source "$CONTAINERS_SCRIPT_DIRECTORY/../core/flags.sh"

# Install the packages every container helper needs. Listed explicitly
# rather than assumed, since a user who answered "n" to the security phase
# would otherwise reach this phase without Docker installed.
log_info "Installing containers packages..."
install_packages "$CONTAINERS_SCRIPT_DIRECTORY/../packages/containers/containers.txt" "$ARCH_PACKAGE_MANAGER" "Installing containers packages..."

# Start and enable Docker, in case the security phase that normally starts
# and enables it was skipped.
start_service "docker"
enable_service "docker"

# Check out the pinned containers repository and ensure the shared network
# every stack attaches to exists.
checkout_containers_repository
ensure_containers_network

# Deploy the shared PostgreSQL and Redis dependencies future stacks such as
# Authelia and NetBird provision their own database or session store in.
sh "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/containers/postgresql.sh"
sh "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/containers/redis.sh"

# Deploy the reverse proxy every later stack fronts itself through.
sh "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/containers/traefik.sh"

# Deploy the authentication portal, fronted through Traefik.
sh "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/containers/authelia.sh"

# Deploy the VPN, registering it as an Authelia OIDC client.
sh "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/containers/netbird.sh"

# Deploy Filestash, fronted through Traefik.
sh "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/containers/filestash.sh"

# Deploy Uptime Kuma, fronted through Traefik.
sh "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/containers/uptime-kuma.sh"

# Deploy LinkStack, fronted through Traefik.
sh "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/containers/linkstack.sh"

# Deploy Dockhand, fronted through Traefik.
sh "$CONTAINERS_SCRIPT_DIRECTORY/../helpers/containers/dockhand.sh"

# Each further container stack helper is added here as its own dedicated
# pull request, in the order documents/roadmap.md describes.

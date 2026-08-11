#!/bin/bash
# shellcheck disable=SC2034  # Variables are sourced and consumed across files; shellcheck cannot see cross-file usage.

# Colors for the script's messages.
NO_COLOR='\e[0m'
BOLD_CYAN='\e[1;36m'
BOLD_GREEN='\e[1;32m'
BOLD_YELLOW='\e[1;33m'
BOLD_RED='\e[1;31m'

# Installation type.
INSTALLATION_TYPE="server"

# Package managers to use.
ARCH_PACKAGE_MANAGER="pacman"
AUR_PACKAGE_MANAGER=""

# Containers integration configuration. The commit is pinned so every
# helper works against the exact same, reviewed revision of the upstream
# repository, never a moving branch tip.
CONTAINERS_REPOSITORY_URL="https://github.com/xrhstosmour/containers.git"
CONTAINERS_REPOSITORY_COMMIT="1b3ae03609525e35544967671f14a7308d653b47"
CONTAINERS_DIRECTORY="/opt/arch-tuner/containers"
CONTAINERS_NETWORK_NAME="internal"

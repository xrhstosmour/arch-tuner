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

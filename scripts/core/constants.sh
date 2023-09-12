#!/bin/bash

# Colors for the script's messages.
NO_COLOR='\e[0m'
BOLD_CYAN='\e[1;36m'
BOLD_GREEN='\e[1;32m'
BOLD_YELLOW='\e[1;33m'
BOLD_RED='\e[1;31m'

# Package managers to use.
ARCH_PACKAGE_MANAGER="pacman"
AUR_PACKAGE_MANAGER="paru"

# Variables to keep if the script ran up to a specific point before rebooting.
ESSENTIALS_COMPLETED=1
INTERFACE_COMPLETED=1
PRIVACY_COMPLETED=1
COMPLETED_UP_TO_FIREWALL=1
SECURITY_COMPLETED=1

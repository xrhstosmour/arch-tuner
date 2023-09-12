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

# Variables to keep if the system rebooted or not.
REBOOTED_AFTER_ESSENTIALS=1
REBOOTED_AFTER_INTERFACE=1
REBOOTED_AFTER_PRIVACY=1
REBOOTED_AFTER_FIREWALL=1
REBOOTED_AFTER_SECURITY=1

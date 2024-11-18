#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
SERVER_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# TODO: Configure users.

# TODO: Configure hostname.

# TODO: Change SSH to different port at the security script.

# TODO: SSH via eliptic keys and 2FA only at the security script.

# TODO: Allow only SSH and HTPPS ports at the security script.

# TODO: Configure fail2ban and geoIPfilter.sh at the security script. More help here: https://technicalciso.com/geoblocking-ssh-on-linux/

# TODO: Set VPN using docker and wg-easy container at the privacy script.

# TODO: Configure authelia at the security script.

# TODO: Add a dashboard home page with links to all services.

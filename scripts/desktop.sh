#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Import constant variables and functions.
source ./constants.sh
source ./functions.sh

# Installing desktop applications.
install_packages "./packages/desktop.txt" "paru"

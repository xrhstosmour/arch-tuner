#!/bin/bash

# Import constant functions.
source ./functions.sh

# Catch exit signal (CTRL + C), to terminate the whole script via the handle_interrupt function.
trap handle_interrupt_signal INT

# Terminate script on error.
set -e

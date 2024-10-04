#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
GIT_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$GIT_SCRIPT_DIRECTORY/../functions/filesystem.sh"

# Constant variables for configuring distributed version control system.
GIT_CONFIGURATION="$HOME/.gitconfig"
GIT_CONFIGURATION_TO_PASS="$GIT_SCRIPT_DIRECTORY/../../configurations/development/tools/git/.gitconfig"

# Configure git tool.
are_git_files_the_same=$(compare_files "$GIT_CONFIGURATION" "$GIT_CONFIGURATION_TO_PASS")
if [ "$are_git_files_the_same" = "false" ]; then
    log_info "Configuring distributed version control system tool..."
    cp -f "$GIT_CONFIGURATION_TO_PASS" "$GIT_CONFIGURATION"
fi

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
DOTFILES_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$DOTFILES_SCRIPT_DIRECTORY/../functions/logs.sh"

# Constant variable for the file path containing the dotfile repository.
DOTFILES="$DOTFILES_SCRIPT_DIRECTORY/../../configurations/interface/dotfiles/dotfiles.txt"

# Clone the dotfiles repository from the cofiguration file.
log_info "Cloning dotfiles repository..."
rm -rf "$HOME/dotfiles" && git clone "$(cat "$DOTFILES")" "$HOME/dotfiles"

# Install dotfiles using the `install.sh` script.
log_info "Installing dotfiles..."
cd "$HOME/dotfiles" && sh ./install.sh

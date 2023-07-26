#!/bin/bash

# Color for the script's messages.
BOLD_CYAN='\e[1;36m'
NO_COLOR='\e[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Update system.
echo -e "\n${BOLD_CYAN}Updating system...${NO_COLOR}"
sudo pacman -S --noconfirm --needed archlinux-keyring &&
    sudo pacman -Syu --noconfirm --needed

# Install essential packages, if they do not exist.
echo -e "\n${BOLD_CYAN}Installing essential packages...${NO_COLOR}"
sudo pacman -S --noconfirm --needed networkmanager base-devel git neovim \
    neofetch btop

# Install paru AUR helper.
echo -e "\n${BOLD_CYAN}Installing paru AUR helper...${NO_COLOR}"
if command -v paru &>/dev/null; then
    echo -e "\n${BOLD_CYAN}paru AUR helper, already exists in your system!${NO_COLOR}"
else

    # Delete old paru directory, if it exists.
    if [ -d "paru" ]; then
        echo -e "\n${BOLD_CYAN}Deleting old paru directory...${NO_COLOR}"
        rm -rf paru
    fi

    # Delete rust package manager, if it exists.
    if pacman -Q rust >/dev/null 2>&1; then
        echo -e "\n${BOLD_CYAN}Deleting rust package manager...${NO_COLOR}"
        sudo pacman -R --noconfirm rust
    fi

    # Changing to stable rust version.
    echo -e "\n${BOLD_CYAN}Changing to stable rust version...${NO_COLOR}"
    sudo pacman -S --noconfirm --needed rustup && rustup default stable

    # Proceed with installation.
    git clone https://aur.archlinux.org/paru.git && cd paru &&
        makepkg -si --noconfirm && cd .. && rm -rf paru
fi

# Configuring paru AUR helper.
echo -e "\n${BOLD_CYAN}Configuring paru AUR helper...${NO_COLOR}"

# Enabling colors in terminal.
echo -e "\n${BOLD_CYAN}Enabling colors in terminal...${NO_COLOR}"
sudo sed -i '/^#.*Color/s/^#//' /etc/pacman.conf

# Skipping review messages.
echo -e "\n${BOLD_CYAN}Skipping review messages...${NO_COLOR}"
grep -qxF 'SkipReview' /etc/paru.conf || echo 'SkipReview' | sudo tee -a /etc/paru.conf >/dev/null

# Installing prompt shell and terminal tools.
echo -e "\n${BOLD_CYAN}Installing prompt shell and terminal tools...${NO_COLOR}"
paru -S --noconfirm --needed starship fish bat exa rm-improved xcp \
    eva zoxide fd sd xh topgrade

# Importing prompt configuration file.
echo -e "\n${BOLD_CYAN}Importing prompt configuration file...${NO_COLOR}"
mkdir -p ~/.config && cp -f ./configurations/prompt/configuration.toml ~/.config/starship.toml

# Importing shell configuration file.
echo -e "\n${BOLD_CYAN}Importing shell configuration file...${NO_COLOR}"
mkdir -p ~/.config/fish && cp -f ./configurations/shell/configuration.fish ~/.config/fish/config.fish
mkdir -p ~/.config/fish/conf.d/ && cp -f ./configurations/shell/aliases.fish ~/.config/fish/conf.d/abbr.fish

# Installing fonts.
echo -e "\n${BOLD_CYAN}Installing fonts...${NO_COLOR}"
paru -S --noconfirm --needed ttf-firacode-nerd

# Check and set default shell if not already set.
echo -e "\n${BOLD_CYAN}Setting default shell...${NO_COLOR}"
current_shell=$(basename "$SHELL")
if [ "$current_shell" != "fish" ]; then
    grep -qxF '/usr/bin/fish' /etc/shells || echo '/usr/bin/fish' | sudo tee -a /etc/shells >/dev/null
    sudo chsh -s /usr/bin/fish $USER
fi

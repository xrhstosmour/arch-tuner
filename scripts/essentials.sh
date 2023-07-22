#!/bin/bash

# Color for the script's messages.
CYAN='\033[1;36m'
NO_COLOR='\033[0m'

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Update system.
echo -e "\n${CYAN}Updating system...${NO_COLOR}"
sudo pacman -S --noconfirm --needed archlinux-keyring &&
    sudo pacman -Syu --noconfirm --needed

# Install essential packages, if they do not exist.
echo -e "\n${CYAN}Installing essential packages...${NO_COLOR}"
sudo pacman -S --noconfirm --needed networkmanager base-devel git neovim \
    neofetch btop

# Install paru AUR helper.
echo -e "\n${CYAN}Installing paru AUR helper...${NO_COLOR}"
if command -v paru &>/dev/null; then
    echo -e "\n${CYAN}paru AUR helper, already exists in your system!${NO_COLOR}"
else

    # Delete old paru directory, if it exists.
    if [ -d "paru" ]; then
        echo -e "\n${CYAN}Deleting old paru directory...${NO_COLOR}"
        rm -rf paru
    fi

    # Proceed with installation.
    git clone https://aur.archlinux.org/paru.git && cd paru &&
        makepkg -si --noconfirm && cd .. && rm -rf paru
fi

# Configuring paru AUR helper.
echo -e "\n${CYAN}Configuring paru AUR helper...${NO_COLOR}"

# Changing to stable rust version.
echo -e "\n${CYAN}Changing to stable rust version...${NO_COLOR}"
paru -S --noconfirm --needed rustup && rustup default stable

# Enabling colors in terminal.
echo -e "\n${CYAN}Enabling colors in terminal...${NO_COLOR}"
sudo sed -i '/^#.*Color/s/^#//' /etc/pacman.conf

# Skipping review messages.
echo -e "\n${CYAN}Skipping review messages...${NO_COLOR}"
echo "SkipReview" | sudo tee -a /etc/paru.conf

# Installing prompt shell and command line tools.
echo -e "\n${CYAN}Installing prompt shell and command line tools...${NO_COLOR}"
paru -S --noconfirm --needed starship fish bat exa rm-improved xcp \
    eva zoxide fd sd xh topgrade

# Configuring command line tools.
echo -e "\n${CYAN}Configuring shell...${NO_COLOR}"

# Setting default shell.
echo -e "\n${CYAN}Setting default shell...${NO_COLOR}"
echo "/usr/bin/fish" | sudo tee -a /etc/shells
sudo chsh -s /usr/bin/fish $USER

# Create shell configuration files.
echo -e "\n${CYAN}Creating shell configuration files...${NO_COLOR}"
mkdir -p ~/.config/fish && touch ~/.config/fish/config.fish
mkdir -p ~/.config/fish/conf.d/ && touch ~/.config/fish/conf.d/abbr.fish

echo -e "\n${CYAN}Enabling command line tools...${NO_COLOR}"

# Enabling starship at fish prompt.
echo "starship init fish | source" >> ~/.config/fish/config.fish

# Enabling zoxide at fish prompt.
echo "zoxide init fish | source" >> ~/.config/fish/config.fish

# Configuring aliases.
echo -e "\n${CYAN}Configuring aliases...${NO_COLOR}"
echo "abbr -a cat 'bat' | source" >> ~/.config/fish/conf.d/abbr.fish
echo "abbr -a ls 'exa --git --icons --color=always --group-directories-first' | source" >> ~/.config/fish/conf.d/abbr.fish
echo "abbr -a cp 'xcp' | source" >> ~/.config/fish/conf.d/abbr.fish
echo "abbr -a rm 'rip' | source" >> ~/.config/fish/conf.d/abbr.fish
echo "abbr -a eva 'calc' | source" >> ~/.config/fish/conf.d/abbr.fish
echo "abbr -a cd 'z' | source" >> ~/.config/fish/conf.d/abbr.fish
echo "abbr -a find 'fd' | source" >> ~/.config/fish/conf.d/abbr.fish
echo "abbr -a sed 'sd' | source" >> ~/.config/fish/conf.d/abbr.fish
echo "abbr -a up 'topgrade' | source" >> ~/.config/fish/conf.d/abbr.fish

# Saving configuration.
echo -e "\n${CYAN}Saving configuration...${NO_COLOR}"
exec fish

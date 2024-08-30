# Enable starship at fish prompt.
starship init fish | source

# Enable zoxide at fish prompt.
zoxide init fish | source

# Disable welcome message.
set -U fish_greeting

# Load custom functions.
source ~/.config/fish/functions/trashy.fish
source ~/.config/fish/functions/logs.fish

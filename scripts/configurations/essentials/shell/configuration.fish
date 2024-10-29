# Enable starship at fish prompt.
starship init fish | source

# Enable zoxide at fish prompt.
zoxide init fish | source

# Enable and configure atuin at fish prompt.
set -gx ATUIN_NOBIND "true"
atuin init fish | source
bind \ch _atuin_search
bind -M insert \ch _atuin_search

# Disable welcome message.
set -U fish_greeting

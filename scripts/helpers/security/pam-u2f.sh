#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
PAM_U2F_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$PAM_U2F_SCRIPT_DIRECTORY/../functions/packages.sh"
source "$PAM_U2F_SCRIPT_DIRECTORY/../functions/filesystem.sh"
source "$PAM_U2F_SCRIPT_DIRECTORY/../functions/ui.sh"

# Constant variables for PAM U2F/FIDO2 hardening. Scoped to sudo only, not
# login or SSH, so a missing or lost authenticator cannot lock out the
# account itself, only privilege escalation.
SUDO_PAM_FILE="/etc/pam.d/sudo"
PAM_U2F_LINE="auth required pam_u2f.so cue"
U2F_KEYS_FILE="$HOME/.config/Yubico/u2f_keys"

# Install PAM U2F/FIDO2 support.
install_packages "pam-u2f" "$ARCH_PACKAGE_MANAGER" "Installing PAM U2F/FIDO2 support..."

# Register a U2F/FIDO2 authenticator if none is registered yet. This needs a
# hardware key physically attached to this machine, useful on bare metal or
# a VPS with console USB passthrough, not a typical headless cloud instance
# with no local hardware access.
if [ ! -s "$U2F_KEYS_FILE" ]; then
    answer=$(choose_option "Register a U2F/FIDO2 authenticator for sudo now? Touch the key when it blinks." "yes" "no")
    if [ "$answer" = "yes" ]; then
        mkdir -p "$(dirname "$U2F_KEYS_FILE")"
        pamu2fcfg >"$U2F_KEYS_FILE"
        log_success "U2F/FIDO2 authenticator registered."
    else
        log_warning "Skipping U2F/FIDO2 registration, sudo will not require a hardware key until one is registered."
    fi
fi

# Require the registered authenticator for sudo, in addition to the existing
# password check.
if [ -s "$U2F_KEYS_FILE" ]; then
    append_line_to_file "$SUDO_PAM_FILE" "$PAM_U2F_LINE" "Requiring a U2F/FIDO2 authenticator for sudo..." >/dev/null
fi

#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
UMASK_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$UMASK_SCRIPT_DIRECTORY/../functions/logs.sh"

# ? Importing constants.sh is not needed, because it is already sourced in the logs script.

# Constant variables for umask configuration.
UMASK_VALUE="077"
LOGIN_FILE="/etc/login.defs"
UMASK_FILES=("/etc/profile" "/etc/bash.bashrc" "$LOGIN_FILE")

# Iterate over the files.
for file in ${UMASK_FILES[@]}; do

    # Check if the file exists.
    if [ -f "$file" ]; then

        # If the file contains an umask setting that doesn't match the desired value, change it.
        # If there's no umask setting and the file isn't /etc/login.defs, add it.
        if grep -q "^umask" $file; then
            if ! grep -q "^umask $UMASK_VALUE" $file; then
                log_info "Setting permissions on file $file..."
                sudo sed -i "s/^umask.*/umask $UMASK_VALUE/" $file
            fi
        elif [ "$file" != "$LOGIN_FILE" ]; then
            log_info "Adding permissions on file $file..."
            echo "umask $UMASK_VALUE" | sudo tee -a $file >/dev/null
        fi

        # If the file is /etc/login.defs and contains a UMASK setting that doesn't match the desired value, change it.
        # If there's no UMASK setting, add it.
        if [ "$file" == "$LOGIN_FILE" ]; then
            if grep -q "^UMASK" $file; then
                if ! grep -q "^UMASK $UMASK_VALUE" $file; then
                    log_info "Setting permissions on file $file..."
                    sudo sed -i "s/^UMASK.*/UMASK $UMASK_VALUE/" $file
                fi
            else
                log_info "Adding permissions on file $file..."
                echo "UMASK $UMASK_VALUE" | sudo tee -a $file >/dev/null
            fi
        fi
    fi
done

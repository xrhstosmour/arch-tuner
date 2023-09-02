#!/bin/bash

# Catch exit signal (CTRL + C), to terminate the whole script.
trap "exit" INT

# Terminate script on error.
set -e

# Constant variable of the scripts' working directory to use for relative paths.
ANTIVIRUS_SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Import functions.
source "$ANTIVIRUS_SCRIPT_DIRECTORY/../functions.sh"

# Install antivirus.
install_packages "clamav" "$AUR_PACKAGE_MANAGER" "Installing antivirus..."

# Get the date from freshclam --version output.
database_date=$(sudo freshclam --version | awk -F'/' '{print $3}' | cut -d ' ' -f1-4)

# Convert to UNIX timestamp.
database_timestamp=$(date --date="$database_date" +%s)

# Get the current date's UNIX timestamp minus one day (86400 seconds).
current_timestamp=$(date --date="yesterday" +%s)

# Check if the database date is earlier than the current date minus one day
if [ "$database_timestamp" -lt "$current_timestamp" ]; then

    # Updating virus database.
    stop_service "clamav-freshclam" "Stopping antivirus update manager..."
    log_info "Updating virus database..."
    sudo freshclam
fi

# Enabling antivirus services.
start_service "clamav-freshclam" "Starting antivirus update manager..."
enable_service "clamav-freshclam" "Enabling antivirus update manager..."
start_service "clamav-daemon" "Starting antivirus service..."
enable_service "clamav-daemon" "Enabling antivirus service..."

# Initialize a flag indicating if a antivirus change has been made.
real_time_scanning_changes_made=1

# Real-time scanning quarantine folder.
REAL_TIME_SCANNING_QUARANTINE_FOLDER="/qrntn"

# Real-time scanning configuration file.
REAL_TIME_SCANNING_CONFIGURATION="/etc/clamav/clamd.conf"

# Real-time scanning constant configuration variables.
REAL_TIME_SCANNING_ACCESS_PREVENTION="OnAccessPrevention"
REAL_TIME_SCANNING_USER="User"
REAL_TIME_SCANNING_USERNAME="clamav"
REAL_TIME_SCANNING_EXCLUDE_USER="OnAccessExcludeUname"
REAL_TIME_SCANNING_INCLUDE_PATH="OnAccessIncludePath"
REAL_TIME_SCANNING_EXCLUDE_PATH="OnAccessExcludePath"

# Creating quarantine folder.
if [ ! -d "$REAL_TIME_SCANNING_QUARANTINE_FOLDER" ]; then
    log_info "Creating quarantine folder..."
    sudo mkdir -p "$REAL_TIME_SCANNING_QUARANTINE_FOLDER"
    sudo chown -R clamav:clamav "$REAL_TIME_SCANNING_QUARANTINE_FOLDER"
    sudo chmod -R 750 "$REAL_TIME_SCANNING_QUARANTINE_FOLDER"

    # Set the real_time_scanning_changes_made flag to 0 (true).
    real_time_scanning_changes_made=0
fi

# To each function execution proceed to change the real_time_scanning_changes_made flag to 0 (true), only if the line was appended (function returned 0 (true)).
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_ACCESS_PREVENTION Yes" "Allowing real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_USER $REAL_TIME_SCANNING_USERNAME" "Setting clamav as the user for real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_EXCLUDE_USER $REAL_TIME_SCANNING_USERNAME" "Excluding clamav user from real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_INCLUDE_PATH /" "Allowing real-time scanning at root folder..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_EXCLUDE_PATH /proc" "Excluding /proc from real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_EXCLUDE_PATH /sys" "Excluding /sys from real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_EXCLUDE_PATH /dev" "Excluding /dev from real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_EXCLUDE_PATH /run" "Excluding /run from real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_EXCLUDE_PATH /tmp" "Excluding /tmp from real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_EXCLUDE_PATH $REAL_TIME_SCANNING_QUARANTINE_FOLDER" "Excluding $REAL_TIME_SCANNING_QUARANTINE_FOLDER from real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_EXCLUDE_PATH /var/tmp" "Excluding /var/tmp from real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_EXCLUDE_PATH /var/run" "Excluding /var/run from real-time scanning..." && real_time_scanning_changes_made=0
append_line_to_file "$REAL_TIME_SCANNING_CONFIGURATION" "$REAL_TIME_SCANNING_EXCLUDE_PATH /var/lock" "Excluding /var/lock from real-time scanning..." && real_time_scanning_changes_made=0

# Enabling real-time scanning.
if [ $real_time_scanning_changes_made -eq 0 ]; then
    stop_process "clamonacc" "Stopping antivirus real-time scanning..."
fi
if ! is_process_running "clamonacc"; then
    log_info "Enabling and starting antivirus real-time scanning in the background..."
    sudo clamonacc --move="$REAL_TIME_SCANNING_QUARANTINE_FOLDER"
fi

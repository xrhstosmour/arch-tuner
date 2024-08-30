# Base function to log a message with a specific color.
# Usage:
#   log_base COLOR "Message to log"
#   log_base COLOR -n "Message to log without newline"
function log_base
    set color $argv[1]
    set prefix "\n"

    # Check if the message should be printed without a newline.
    if test "$argv[2]" = "-n"
        set prefix ""
        set argv $argv[3..-1]
    else
        set argv $argv[2..-1]
    end

    set message "$argv[1]"
    echo -e "$prefix$color$message$NO_COLOR" >&2
end

# Function to log an info message.
# Usage:
#   log_info "Info message to log"
#   log_info -n "Info message to log without newline"
function log_info
    log_base $BOLD_CYAN $argv
end

# Function to log a success message.
# Usage:
#   log_success "Success message to log"
#   log_success -n "Success message to log without newline"
function log_success
    log_base $BOLD_GREEN $argv
end

# Function to log a warning message.
# Usage:
#   log_warning "Warning message to log"
#   log_warning -n "Warning message to log without newline"
function log_warning
    log_base $BOLD_YELLOW $argv
end

# Function to log an error message.
# Usage:
#   log_error "Error message to log"
#   log_error -n "Error message to log without newline"
function log_error
    log_base $BOLD_RED $argv
end

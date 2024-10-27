# TODO: Replace `fzf` with `skim`.
# Function to restore files from trash.
# Usage:
#   trash_restore
function trash_restore
    set list (trash list | fzf --multi --bind 'esc:abort')
    if test -n "$list"
        echo $list | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trash restore --match=exact --force
    else
        log_error -n "Aborted"
    end
end

# Function to empty trash.
# Usage:
#   trash_empty
function trash_empty
    set list (trash list | fzf --multi --bind 'esc:abort')
    if test -n "$list"
        echo $list | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trash empty --match=exact --force
    else
        log_error -n "Aborted"
    end
end

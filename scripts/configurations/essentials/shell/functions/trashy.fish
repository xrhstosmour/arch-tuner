function tr
    set list (trash list | fzf --multi --bind 'esc:abort')
    if test -n "$list"
        echo $list | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trash restore --match=exact --force
    else
        echo "Aborted"
    end
end

function te
    set list (trash list | fzf --multi --bind 'esc:abort')
    if test -n "$list"
        echo $list | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trash empty --match=exact --force
    else
        echo "Aborted"
    end
end

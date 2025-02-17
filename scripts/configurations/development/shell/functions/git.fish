# TODO: Replace `fzf` with `skim`.
# Function to stash changes with a default name.
# Usage:
#   git_stash "Stash message" or git_stash
function git_stash
    if test -n "$argv[1]"
        set name "$argv[1]"
    else
        set name (date +'%d_%m_%YT%H_%M_%S')
    end

    git stash push -u -m "$name"
end


# Function to get the deafult branch.
# Usage:
#   git_get_default_branch
function git_get_default_branch
    set default_branch ""

    # Attempt to get the default branch from the remote repository
    set default_branch (git remote show origin | grep 'HEAD branch' | awk '{print $NF}')
    if test -n "$default_branch"
        set default_branch "origin/$default_branch"
    else
        log_error "Could not determine the default branch!"
        return 1
    end

    echo "$default_branch"
end

# Function to fetch and rebase the current branch onto default branch with autostash enabled by default.
# Usage:
#   git_fetch_and_rebase optional_branch/"" true/false
function git_fetch_and_rebase
    set branch_to_rebase_onto ""
    set autostash_enabled "true"

    # Parse arguments.
    if test -n "$argv[1]"
        set branch_to_rebase_onto "$argv[1]"
    end

    if test -n "$argv[2]"
        set autostash_enabled "$argv[2]"
    end

    # Determine branch to rebase onto.
    if test -z "$branch_to_rebase_onto"

        # Get the default branch.
        set branch_to_rebase_onto (git_get_default_branch)

        # Check if the `git_get_default_branch` function succeeded.
        if test $status -ne 0
            log_error "Failed to determine the default branch!"
            return 1
        end
    else
        # Fetch the specific branch if provided
        git fetch origin $branch_to_rebase_onto
        set branch_to_rebase_onto "origin/$branch_to_rebase_onto"
    end


    # Check for uncommitted changes if autostash is disabled.
    if test "$autostash_enabled" = "false" -a (not git diff-index --quiet HEAD --)
        log_error "Commit or stash your uncommitted changes before rebasing!"
        return 1
    end

    log_info "Fetching and rebasing onto `$branch_to_rebase_onto`..."

    # Perform fetch and rebase with or without autostash.
    if test "$autostash_enabled" = "true"
        git fetch && git rebase -i "$branch_to_rebase_onto" --autosquash --autostash
    else
        git fetch && git rebase -i "$branch_to_rebase_onto" --autosquash
    end
end

# Function to choose commit to fixup.
# Pressing:
#   - ENTER will fixup the commit
#   - TAB will show the commit changes
#   - ? will toggle the preview
# Usage:
#   git_auto_fix_up
function git_auto_fix_up
    # Get the name of the current branch.
    set current_branch (git rev-parse --abbrev-ref HEAD)

    # Get the default branch.
    set default_branch (git_get_default_branch)
    if test $status -ne 0
        return 1
    end

    # Get the log of the current branch excluding commits from the upstream branch.
    set -l commits_list (git log --oneline --pretty=format:'%h | %s' --no-merges $default_branch..$current_branch | string split '\n')

    # Check if the commits list is empty.
    if test -z "$commits_list"
        echo "No commits found!"
        return 1
    end

    # Loop through the array.
    for line in $commits_list

        # Get commit hash and message.
        set commit_hash (echo $line | awk '{print $1}')
        set commit_message (echo $line | cut -d' ' -f3-)

        # Exclude lines where commit message starts with fixup!
        if not string match -q 'fixup!*' "$commit_message"

            # Print the commit hash and message.
            echo -e "$BOLD_YELLOW$commit_hash$NO_COLOR $BOLD_GREEN|$NO_COLOR $commit_message"
        end
    end | fzf --multi --ansi --bind 'enter:execute(git commit --fixup {1} --no-verify)+abort,tab:execute(git diff {1}^!),?:toggle-preview' --preview '

        # Keep the commit hash and message.
        set commit_hash {1}
        set commit_message (echo {2..} | cut -d"|" -f2- | sed "s/^ //")

        # Get the author, date, and files paths for the commit.
        set author (git show -s --format="%an" $commit_hash)
        set date (git show -s --format="%ad" --date=format-local:"on %d/%m/%Y at %H:%M:%S" $commit_hash)
        set files (git diff-tree --no-commit-id --name-only -r $commit_hash)

        # Color constants are not working in the preview window so we use the hardcoded ANSI escape codes.
        # Add "- " in front of each file line with green color.
        set formatted_files ""
        for file in $files
            set formatted_files "$formatted_files\e[1;32m-\e[0m $file\n"
        end

        echo -e "\e[1;33mHash:\e[0m $commit_hash"
        echo -e "\e[1;33mMessage:\e[0m $commit_message\n"
        echo -e "\e[1;36mAuthor:\e[0m $author"
        echo -e "\e[1;36mDate:\e[0m $date\n"

        # Show "Files:" and the list of files only if there are any files.
        if test -n "$files"
            echo -e "\e[1;32mFiles:\e[0m"
            echo -e "$formatted_files"
        end
    ' --preview-window=right:50%:hidden:wrap
end

# Function to show/list git stashes and interact with them using fzf.
# Pressing:
#   - ENTER will apply the stash
#   - DELETE will drop the stash
#   - TAB will show the file changes
#   - ? will toggle the preview
# Usage:
#   git_stash_list
function git_stash_list

    # Get the stash list as an array.
    set -l stash_list (git stash list -n 50 --pretty=format:'%h|%s' | string split '\n')

    # Check if the stash list is empty.
    if test -z "$stash_list"
        log_error "No stashes found!"
        return 1
    end

    # Loop through the array.
    for line in $stash_list

        # Extract the stash hash by splitting based on "|".
        set stash_hash (echo "$line" | cut -d'|' -f1 | xargs)

        # Extract the stash message and keep it clean, without the branch.
        set stash_message (echo "$line" | cut -d'|' -f2- | xargs)
        set stash_message (echo "$stash_message" | sed 's/^On [^:]*: //')

        # Print the branch related to the stash and its message.
        echo -e "$BOLD_YELLOW$stash_hash$NO_COLOR $BOLD_GREEN|$NO_COLOR $stash_message"
    end | fzf --ansi --bind 'enter:execute(git stash apply (git log -g stash --format="%h %gd" | grep -m 1 {1} | awk "{print \$2}"))+abort,delete:execute(git stash drop (git log -g stash --format="%h %gd" | grep -m 1 {1} | awk "{print \$2}"))+abort,tab:execute(git stash show -p {1}),?:toggle-preview' --preview '
        # Extract stash hash and message from the selection.
        set stash_hash {1}
        set stash_message (echo {2..} | cut -d"|" -f2- | sed "s/^ //")

        # Get the stash index in the stash@{index} format.
        set stash_index (git log -g stash --format="%h %gd" | grep -m 1 "$stash_hash" | awk "{print \$2}")

        # Get the branch from git stash list excluding the stash message.
        set branch (git stash list --pretty=format:"%s" | grep -m 1 "$stash_message" | sed "s/.*On \(.*\): $stash_message/\1/" | xargs)

        # Get the date of the stash.
        set date (git show -s --format="%ad" --date=format-local:"%d/%m/%Y at %H:%M:%S" $stash_hash)

        # Get the list of files affected by the stash.
        set files (git stash show -p $stash_hash --name-only)

        # Color constants are not working in the preview window so we use the hardcoded ANSI escape codes.
        # Add "- " in front of each file line with green color.
        set formatted_files ""
        for file in $files
            set formatted_files "$formatted_files\e[1;32m-\e[0m $file\n"
        end

        echo -e "\e[1;33mIndex:\e[0m $stash_index"
        echo -e "\e[1;33mHash:\e[0m $stash_hash"
        echo -e "\e[1;33mBranch:\e[0m $branch\n"
        echo -e "\e[1;36mMessage:\e[0m $stash_message"
        echo -e "\e[1;36mDate:\e[0m $date\n"

        # Show "Files:" and the list of files only if there are any files.
        if test -n "$files"
            echo -e "\e[1;32mFiles:\e[0m"
            echo -e "$formatted_files"
        end
    ' --preview-window=right:50%:hidden:wrap
end

# Function to show git log for the current branch and interact with it using fzf.
# Pressing:
#   - ENTER will reset the current branch to the selected commit
#   - TAB will show the commit changes
#   - ? will toggle the preview
# Usage:
#   git_log_current_branch
function git_log_current_branch

    # Get the name of the current branch.
    set current_branch (git rev-parse --abbrev-ref HEAD)

    # Get the base branch.
    set default_branch (git_get_default_branch)
    if test $status -ne 0
        return 1
    end

    # Get the log of the current branch excluding commits from the upstream branch.
    set -l log_list (git log --oneline --pretty=format:'%h | %s' $default_branch..$current_branch | string split '\n')

    # Check if the log list is empty.
    if test -z "$log_list"
        echo "No commits found!"
        return 1
    end

    # Loop through the array.
    for line in $log_list

        # Extract the commit hash and message.
        set commit_hash (echo "$line" | awk '{print $1}')
        set commit_message (echo "$line" | cut -d' ' -f3-)

        # Print the commit hash and message.
        echo -e "$BOLD_YELLOW$commit_hash$NO_COLOR $BOLD_GREEN|$NO_COLOR $commit_message"
    end | fzf --ansi --bind 'enter:execute(git reset --hard {1})+abort,tab:execute(git diff {1}^!),?:toggle-preview' --preview '
        # Extract commit hash and message from the selection.
        set commit_hash {1}
        set commit_message (echo {2..} | cut -d"|" -f2- | sed "s/^ //")

        # Get the author, date, and files paths for the commit.
        set author (git show -s --format="%an" $commit_hash)
        set date (git show -s --format="%ad" --date=format-local:"%d/%m/%Y at %H:%M:%S" $commit_hash)
        set files (git diff-tree --no-commit-id --name-only -r $commit_hash)

        # Color constants are not working in the preview window so we use the hardcoded ANSI escape codes.
        # Add "- " in front of each file line with green color.
        set formatted_files ""
        for file in $files
            set formatted_files "$formatted_files\e[1;32m-\e[0m $file\n"
        end

        echo -e "\e[1;33mHash:\e[0m $commit_hash"
        echo -e "\e[1;33mMessage:\e[0m $commit_message\n"
        echo -e "\e[1;36mAuthor:\e[0m $author"
        echo -e "\e[1;36mDate:\e[0m $date\n"

        # Show "Files:" and the list of files only if there are any files.
        if test -n "$files"
            echo -e "\e[1;32mFiles:\e[0m"
            echo -e "$formatted_files"
        end
    ' --preview-window=right:50%:hidden:wrap
end

# Function to show all branches not merged or deleted and interact with them using fzf.
# Pressing:
#   - ENTER will checkout to the selected branch
#   - DELETE will delete the selected branch
#   - TAB will show the diff of the selected branch
#   - ? will toggle the preview and show more details
# Usage:
#   git_list_branches
function git_list_branches
    # Get the default branch.
    set default_branch (git_get_default_branch)
    if test $status -ne 0
        return 1
    end

    # Get the current branch.
    set current_branch (git branch --show-current)

    # Get the list of all branches.
    set -l all_branches (git branch -av --format='%(refname:short)' | string split '\n')

    # Get the list of all local not pushed branches.
    set -l not_pushed_local_branches (git for-each-ref --format="%(refname:short) %(push:track)" refs/heads | grep '\[gone\]' | awk '{print $1}' | string split '\n')

    # Get the list of all merged branches.
    set -l merged_branches (git branch -a --merged $default_branch | sed 's/^[* ]*//' | string split '\n')

    # Exclude merged branches from all branches.
    set -l branch_list (echo "$all_branches" | grep -v -F -f <(echo "$merged_branches") | string split '\n')

    # Exclude remote branches that have a corresponding local branch.
    set -l local_branches (git branch --format='%(refname:short)' | string split '\n')
    set -l branch_list (echo "$branch_list" | grep -v -F -f <(echo "$local_branches" | sed 's/^/origin\//') | string split '\n')

    # Exclude `origin/HEAD`
    set -l branch_list (echo "$branch_list" | grep -v '^origin/HEAD$' | string split '\n')

    # Add the not pushed local branches to the list.
    set -l branch_list (echo -e "$branch_list\n$not_pushed_local_branches" | sort -u | string split '\n')

    # Check if the branch list is empty.
    if test -z "$branch_list"
        echo "No branches found!"
        return 1
    end

    # Loop through the array.
    for line in $branch_list
        # Check if the branch is the current one.
        if test "$line" = "$current_branch"
            # Print the current branch name in green.
            echo -e "$BOLD_YELLOW$line$NO_COLOR"
        else
            # Print the branch name in yellow.
            echo -e "$BOLD_GREEN$line$NO_COLOR"
        end
    end | fzf --ansi --bind 'enter:execute(git checkout {1})+abort,delete:execute(git branch -d {1})+abort,tab:execute(git diff {1})+abort,?:toggle-preview' --preview '
        # Extract branch name from the selection.
        set branch_name {1}

        # Get the author, date, and files for the branch.
        set author (git log -1 --pretty=format:"%an" $branch_name)
        set date (git log -1 --pretty=format:"%ad" --date=format-local:"%d/%m/%Y at %H:%M:%S" $branch_name)
        set files (git ls-tree -r $branch_name --name-only)

        # Color constants are not working in the preview window so we use the hardcoded ANSI escape codes.
        # Add "- " in front of each file line with green color.
        set formatted_files ""
        for file in $files
            set formatted_files "$formatted_files\e[1;32m-\e[0m $file\n"
        end

        echo -e "\e[1;33mBranch:\e[0m $branch_name\n"
        echo -e "\e[1;36mAuthor:\e[0m $author"
        echo -e "\e[1;36mDate:\e[0m $date\n"

        # Show "Files:" and the list of files only if there are any files.
        if test -n "$files"
            echo -e "\e[1;32mFiles:\e[0m"
            echo -e "$formatted_files"
        end
    ' --preview-window=right:50%:hidden:wrap
end

# Function to cherry-pick specific commits from different branches.
# Show a list of the branch | commit hash | commit message.
# Pressing:
#   - ENTER will cherry-pick the commit
#   - ? will toggle the preview and show more details
# Usage:
#   git_cherry_pick_commit
function git_cherry_pick_commit
    # Get the current branch.
    set current_branch (git branch --show-current)

    # Get the list of commits from all remote branches except the current one.
    set -l commits_list (git log --oneline --pretty=format:'%h | %s' --all --remotes | grep -v "origin/$current_branch" | string split '\n')

    # Check if the commit list is empty.
    if test -z "$commits_list"
        echo "No commits found!"
        return 1
    end

    # Loop through the array.
    for line in $commits_list
        # Get commit hash and message.
        set commit_hash (echo "$line" | awk '{print $1}')
        set commit_message (echo "$line" | cut -d' ' -f3-)

        # Print the commit hash and message.
        echo -e "$BOLD_YELLOW$commit_hash$NO_COLOR $BOLD_GREEN|$NO_COLOR $commit_message"
    end | fzf --ansi --bind 'enter:execute(git cherry-pick {1})+abort,?:toggle-preview' --preview '
        # Keep the commit hash and message.
        set commit_hash {1}
        set commit_message (echo {2..} | cut -d"|" -f2- | sed "s/^ //")

        # Get the branch, author, date, and files paths for the commit.
        set branch (git branch -a --contains $commit_hash | grep "remotes/origin/" | sed "s#remotes/##")

        set author (git show -s --format="%an" $commit_hash)
        set date (git show -s --format="%ad" --date=format-local:"%d/%m/%Y at %H:%M:%S" $commit_hash)
        set files (git diff-tree --no-commit-id --name-only -r $commit_hash)

        # Color constants are not working in the preview window so we use the hardcoded ANSI escape codes.
        # Add "- " in front of each file line with green color.
        set formatted_files ""
        for file in $files
            set formatted_files "$formatted_files\e[1;32m-\e[0m $file\n"
        end

        echo -e "\e[1;33mHash:\e[0m $commit_hash"
        echo -e "\e[1;33mBranch:\e[0m $branch"
        echo -e "\e[1;33mMessage:\e[0m $commit_message\n"
        echo -e "\e[1;36mAuthor:\e[0m $author"
        echo -e "\e[1;36mDate:\e[0m $date\n"

        # Show "Files:" and the list of files only if there are any files.
        if test -n "$files"
            echo -e "\e[1;32mFiles:\e[0m"
            echo -e "$formatted_files"
        end
    ' --preview-window=right:50%:hidden:wrap
end

# Function to merge the current branch to default branch.
# Usage:
#   git_merge_to_default_branch [branch_name] [pr_number]
function git_merge_to_default_branch
    set remote "origin"
    set current_branch ""
    set upstream_branch ""
    set default_branch ""
    set branch_to_be_merged ""
    set new_commits_count 0
    set no_ff_option ""
    set merge_commit_msg ""

    # Check if a rebase is ongoing.
    if test -d (git rev-parse --git-dir)/rebase-merge -o -d (git rev-parse --git-dir)/rebase-apply
        log_error "Rebase in progress, operation stopped!"
        return 1
    end

    # Checkout the specified branch if provided.
    if test -n "$argv[1]"
        log_info "Checking out `$argv[1]` branch..."
        git checkout "$argv[1]"
    end

    set current_branch (git rev-parse --abbrev-ref HEAD)
    log_info "Currently on `$current_branch` branch."

    # Resolve upstream branch.
    set upstream_branch (git rev-parse --abbrev-ref "@{upstream}" ^/dev/null; or echo "$current_branch")
    if not git ls-remote --heads --exit-code "$remote" "$upstream_branch" ^/dev/null
        read -P "Please enter the branch name for fetch/push operations: " upstream_branch
    end
    log_info "Branch tracking the remote branch `$upstream_branch`."

    # Fetch and rebase current branch onto default branch.
    git_fetch_and_rebase "" false
    if test $status -ne 0
        log_error "Rebase failed, resolve conflicts/errors before running the script again!"
        return 1
    end

    # Get the default branch using the `git_get_default_branch` function.
    set default_branch (git_get_default_branch)

    # Force push current branch.
    log_info "Force pushing `$current_branch` to `$remote/$upstream_branch`..."
    git push "$remote" "HEAD:$upstream_branch" --force-with-lease

    # Merge to default branch.
    set branch_to_be_merged "$remote/$upstream_branch"
    log_info "Merging `$current_branch` to `$branch_to_be_merged`..."
    git checkout (string replace "origin/" "" "$default_branch")
    git reset --hard "$default_branch"

    # Check if the branch to be merged has more than one commit.
    set new_commits_count (git rev-list --count "$default_branch..$branch_to_be_merged")
    if test "$new_commits_count" -gt 1
        set no_ff_option "--no-ff"
    end

    # Check if a PR number is provided.
    if test -n "$no_ff_option"
        set merge_commit_msg "-m Merge branch `$branch_to_be_merged`"
        if test -n "$argv[2]"
            set merge_commit_msg "$merge_commit_msg -m Closes #$argv[2]"
        end
    end

    git merge "$branch_to_be_merged" $no_ff_option $merge_commit_msg

    # Extract the branch name without the 'origin/' prefix.
    set local_branch (string replace "origin/" "" "$default_branch")

    log_info "The commits listed below will be pushed to `$default_branch`:"
    git --no-pager log --decorate --graph --oneline "$local_branch...$default_branch"

    # Prompt the user for confirmation.
    log_warning "Would you like to push your local commits to `$default_branch`? (Y/N) "
    read push_to_default_branch
    if test "$push_to_default_branch" = "y" -o "$push_to_default_branch" = "Y"
        git push "$remote" "$local_branch"
        if test $status -ne 0
            log_error "Push to `$default_branch` failed!"
            git reset --hard HEAD^
            git checkout "$current_branch"
            return 1
        end
        log_success "Push to `$default_branch` was successful!"
    else
        log_info "Push to `$default_branch` was aborted!"
        git reset --hard HEAD^
        git checkout "$current_branch"
    end
end

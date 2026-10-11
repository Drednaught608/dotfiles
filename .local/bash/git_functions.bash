# Git Functions

git() { # Allows for dgit to trigger when in home directory
    if [[ "$PWD" = "$HOME" && "$1" != "clone" && "$1" != "config" ]] && command -v dgit &> /dev/null; then
        command dgit "$@"
    else
        command git "$@"
    fi
}

git_staging() { # Allows for adding & removing all from staging
    local status branch
    if ! type -P git > /dev/null; then
        echo "Git is not installed."
    # One call for the whole repo: "# branch.head <name>", then a line per change:
    # "? path" untracked, "1 XY ..." / "2 XY ..." (X staged, Y unstaged, "." none), "u ..." conflict
    elif status=$(git status --porcelain=v2 --branch --untracked-files=normal 2> /dev/null); then # Fails outside a repo
        branch=${status#*'# branch.head '}
        branch=${branch%%$'\n'*}
        [[ $branch == '(detached)' ]] && branch='detached HEAD'
        branch="* "$'\e[32m'"$branch"$'\e[m' # git branch's current-branch green
        if [[ $status == *$'\n? '* || $status == *$'\n'[12u]' '?[!.]' '* ]]; then # Untracked or unstaged
            git add --all
            echo "$branch Staged all files."
        elif [[ $status == *$'\n'[12]' '* ]]; then # Only staged
            git reset --quiet
            echo "$branch Unstaged all files."
        else
            echo "$branch Working tree clean."
        fi
    else
        echo "Not in a Git repository."
    fi
}

git_sync() { # Pushes when you have unpushed commits, otherwise pulls
    local ahead
    # Counts commits on this branch that its upstream lacks; local, no network
    if ahead=$(git rev-list --count '@{upstream}..HEAD' 2> /dev/null); then
        if (( ahead > 0 )); then
            git push
        else
            git pull --ff-only
        fi
    else
        git push # No upstream yet, so push sets one up (push.autoSetupRemote)
    fi
}

git_commit() {
    git commit
}
git_fetch() {
    git fetch
}
git_status() { # Shows untracked files as unstaged additions (" A") instead of "??"
    local out color=never
    [ -t 1 ] && color=always # Git drops its colors when captured, so ask for them
    out=$(git -c color.status=$color status -sbuall) || return
    out=${out//$'\n\e[31m??\e[m '/$'\n \e[31mA\e[m '} # Colored
    out=${out//$'\n?? '/$'\n A '} # Plain
    printf '%s\n' "$out"
}
git_branches() {
    git branch -avv --color=always | grep -v -- ' -> '
}
git_log() {
    git log --oneline -n 11 --graph
}
git_diff() {
    git --no-pager diff HEAD
}

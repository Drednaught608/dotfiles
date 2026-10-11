# Git Functions

git() { # Allows for dgit to trigger when in home directory
    # On Windows, Ctrl+C in the commit editor is also reported as having interrupted git.exe, so
    # Bash prints a blank line and drops the rest of the command line. A subshell takes that instead.
    if [[ "$1" = "commit" && "$BASH_SUBSHELL" -eq 0 ]] && [[ $OSTYPE == msys* || $OSTYPE == cygwin* ]]; then
        ( git "$@" )
    elif [[ "$PWD" = "$HOME" && "$1" != "clone" && "$1" != "config" ]] && command -v dgit &> /dev/null; then
        command dgit "$@"
    else
        command git "$@"
    fi
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

git_tracked() { # Toggles staging between "every change to tracked files, nothing else" and empty
    local status branch gitdir
    # One call: "# branch.head <name>", then a line per change: "1 XY ..." / "2 XY ..."
    # (X staged, Y unstaged, "." neither), "u ..." conflict, "? path" untracked
    if ! status=$(git status --porcelain=v2 --branch --untracked-files=normal 2> /dev/null); then
        echo "Not in a Git repository."
        return 1
    fi
    branch=${status#*'# branch.head '}
    branch=${branch%%$'\n'*}
    [[ $branch == '(detached)' ]] && branch='detached HEAD'
    branch="* "$'\e[32m'"$branch"$'\e[m' # git branch's current-branch green

    if [[ $status == *$'\nu '* ]]; then
        echo "$branch Conflicts to resolve first; staging left alone."
        return 1
    fi
    if [[ $status == *$'\n'[12]' '[!.]* ]]; then # Something is staged, so a reset is coming
        # "git reset" also forgets a merge, cherry-pick or revert in progress; never do that from a toggle
        gitdir=$(git rev-parse --git-dir) || return
        if [ -e "$gitdir/MERGE_HEAD" ] || [ -e "$gitdir/CHERRY_PICK_HEAD" ] || [ -e "$gitdir/REVERT_HEAD" ]; then
            echo "$branch A merge, cherry-pick or revert is in progress; staging left alone."
            return 1
        fi
        git reset --quiet || return
        if [[ $status != *$'\n'[12]' '?[!.]' '* ]]; then # Every tracked change was staged: leave it empty
            echo "$branch Unstaged all files."
            return
        fi
    fi
    if [[ $status == *$'\n'[12]' '?[!.]' '* ]]; then # Tracked changes that are not staged
        git add --update && echo "$branch Staged all tracked files."
    elif [[ $status == *$'\n'[12?]' '* ]]; then # Only untracked files
        echo "$branch No changes to tracked files."
    else
        echo "$branch Working tree clean."
    fi
}

git_flagged() { # True if path $1 looks like a secret or junk; sets REPLY to what to list: the path, or the junk folder it is in
    local path=/$1 folder
    for folder in node_modules __pycache__ .cache .venv venv .pytest_cache .mypy_cache .ruff_cache .tox .idea; do
        if [[ $path == */"$folder"/* ]]; then
            REPLY=${path%%"/$folder/"*}/$folder/
            REPLY=${REPLY#/}
            return
        fi
    done
    REPLY=$1
    case ${1##*/} in
        .env.example|.env.sample|.env.template|.env.dist) return 1 ;; # Meant to be committed
        .env|.env.*|*.pem|*.key|*.p12|*.pfx|*.ppk|*.jks|*.keystore|*.kdbx) ;; # Secrets
        id_rsa|id_dsa|id_ecdsa|id_ed25519|.netrc|.pgpass|.htpasswd|credentials.json|secrets.*) ;;
        .DS_Store|Thumbs.db|desktop.ini|*.pyc|*.pyo|.*.sw?|*~|*.tmp|.*cache) ;; # Junk
        *) return 1 ;;
    esac
}

git_commit_key() { # Waits for one of git_commit's prompt keys and sets REPLY to it (^Q for Ctrl+Q)
    while :; do
        IFS= read -rsn1 REPLY || REPLY=q
        # Arrow and function keys send Esc, then "[" or "O", then more, ending in a letter or "~".
        # Swallow the whole sequence, or its last letter (Up ends in "A") would count as an answer.
        if [ "$REPLY" = $'\e' ]; then
            IFS= read -rsn1 REPLY || REPLY=q
            if [[ $REPLY == [[O] ]]; then
                while IFS= read -rsn1 REPLY && [[ $REPLY != [@-~] ]]; do :; done
                continue
            fi
        fi
        case $REPLY in
            [yYnNaAqQ]) return ;;
            $'\x11') REPLY=^Q; return ;;
        esac
    done
}

git_commit() { # Commits what you staged, or everything if nothing is staged, offering to leave out secrets and junk
    local record path key status old_trap tty_state skip= any= staged= conflict= without= tree= last_new= last_added=
    local new=() added=() added_paths=() found=() excludes=()
    # One call: "? path" untracked, "1 XY ... path" / "2 XY ... path" changed (X staged, Y unstaged), "u ..." conflict
    while IFS= read -r -d '' record; do
        any=1
        if [ -n "$skip" ]; then skip=; continue; fi # The old path that follows a rename
        case $record in
            '? '*)
                if git_flagged "${record:2}" && [ "$REPLY" != "$last_new" ]; then
                    new+=("$REPLY"); last_new=$REPLY
                fi ;;
            [12]' '*)
                [ "${record:2:1}" = . ] || staged=1
                [ "${record:0:1}" = 1 ] || skip=1
                path=${record#* * * * * * * * }
                if [ "${record:2:1}" = A ] && git_flagged "$path"; then # Only files this commit would add
                    added_paths+=("$path")
                    [ "$REPLY" = "$last_added" ] || { added+=("$REPLY"); last_added=$REPLY; }
                fi ;;
            'u '*) conflict=1 ;;
        esac
    done < <(git status --porcelain=v2 -z --untracked-files=all 2> /dev/null)
    # Nothing to do, a conflict, or not a repo: Git says so itself
    if [ -z "$any" ] || [ -n "$conflict" ]; then git commit; return; fi

    if [ -n "$staged" ]; then found=("${added[@]}"); else found=("${new[@]}"); fi
    if (( ${#found[@]} )); then
        echo "Possible secrets or junk:"
        printf '  %s\n' "${found[@]}"
        printf 'Commit without them? [y/n] (a/q aborts) ' # Ctrl+Q and Ctrl+C abort too
        # The terminal keeps Ctrl+Q for itself (flow control); turn that off while asking, so it gets here
        tty_state=$(stty -g 2> /dev/null) && stty -ixon
        # Ctrl+C only leaves git_commit_key, so the terminal is put back below whichever key ends the wait.
        # It does nothing in the instant before or after that call, where "return" would leave git_commit.
        old_trap=$(trap -p INT)
        trap '[ "${FUNCNAME[0]}" != git_commit_key ] || { REPLY=^C; return; }' INT
        git_commit_key
        eval "${old_trap:-trap - INT}"
        [ -z "$tty_state" ] || stty "$tty_state"
        key=$REPLY
        echo "$key"
        case $key in
            [yY]) without=1 ;;
            [nN]) ;;
            *) echo "Aborted, nothing changed."; return 1 ;;
        esac
    fi

    # From here staging changes. Ctrl+C would stop this function along with Git and leave
    # it changed, so trap it: Git still stops, and the steps that put staging back still run.
    old_trap=$(trap -p INT)
    trap : INT
    if [ -n "$staged" ]; then # Only what you staged; nothing more gets added
        if [ -n "$without" ]; then
            tree=$(git write-tree) &&
                printf ':(top,literal)%s\0' "${added_paths[@]}" |
                git rm --cached --force --quiet --pathspec-from-file=- --pathspec-file-nul
        fi && git commit
        status=$?
        if (( status )) && [ -n "$tree" ]; then
            git read-tree "$tree" # Back to exactly what you had staged
        fi
    else # Nothing staged: stage everything, as "git add --all" would
        if [ -n "$without" ]; then
            for path in "${found[@]}"; do excludes+=(":(top,literal,exclude)$path"); done
            git add --all -- ':/' "${excludes[@]}"
        else
            git add --all
        fi && git commit
        status=$?
        if (( status )); then
            git reset --quiet # Back to nothing staged, as it was
        fi
    fi
    eval "${old_trap:-trap - INT}" # Ctrl+C behaves as it did before
    return $status
}

# Git Functions

git() { # Allows for dgit to trigger when in home directory
    # On Windows, Ctrl+C in the commit editor is also reported as having interrupted git.exe, so
    # Bash prints a blank line and drops the rest of the command line. A subshell takes that instead.
    if [[ "$1" = "commit" && "$BASH_SUBSHELL" -eq 0 ]] && [[ $OSTYPE == msys* || $OSTYPE == cygwin* ]]; then
        ( git "$@" )
    # Bare "git", "git --help" and "git -h" are about git itself, so they never go to dgit
    elif [[ "$PWD" = "$HOME" && $# -gt 0 && "$1" != "--help" && "$1" != "-h" && "$1" != "clone" && "$1" != "config" ]] &&
        command -v dgit &> /dev/null; then
        command dgit "$@"
    else
        command git "$@"
    fi
}

git_status() {
    git status -sbuall
}
git_branches() {
    git branch -avv --color=always | grep -v -- ' -> '
}
git_diff() {
    git --no-pager diff HEAD
}

git_fetch() { # Fetches, and follows a remote's HEAD (its default branch) if that changed there
    local line status copy=${TMPDIR:-/tmp}/git_fetch.$$ progress=()
    [ -t 2 ] && progress=(--progress) # Its output goes through tee, so ask for the meter a screen gets
    # For this fetch only, never saved: Git says when a remote's HEAD differs from ours (Git 2.48+).
    # The output shows as it comes, and tee keeps a copy to look for that in afterwards.
    git -c fetch.followRemoteHEAD=warn -c advice.fetchRemoteHEADWarn=false fetch "${progress[@]}" 2>&1 |
        tee "$copy" >&2
    status=${PIPESTATUS[0]}
    while IFS= read -r line; do
        if [[ $line =~ ^\'HEAD\'\ at\ \'(.+)\'\ is\ \'(.+)\',\ but\ we\ have\ \'(.+)\'\ locally\.$ ]]; then
            git remote set-head "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" > /dev/null &&
                echo "${BASH_REMATCH[1]}/HEAD: ${BASH_REMATCH[3]} -> ${BASH_REMATCH[2]}"
        fi
    done < "$copy"
    rm -f "$copy"
    return $status
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

git_log() { # git_log [count]: the last count commits; by default 11, or as many as fit on screen
    if [ -n "$1" ]; then
        git --no-pager log --oneline -n "$1" --graph
        return
    fi
    local out line plain prompt rows cols room used shown=0 esc=$'\e\[[0-9;]*m'
    if [ ! -t 1 ]; then # Not printing to a screen, so nothing to fit
        git --no-pager log --oneline -n 11 --graph
        return
    fi
    # Captured, so ask for what Git only gives a screen: colors and the branch labels
    out=$(git --no-pager log --oneline -n 11 --graph --color=always --decorate) || return
    rows=${LINES:-$(tput lines 2> /dev/null)} cols=${COLUMNS:-$(tput cols 2> /dev/null)}
    rows=${rows:-999} cols=${cols:-999}
    # The prompt as shown, to measure the rows it takes (Bash 4.4 or newer; else one row)
    prompt=
    if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) )); then
        prompt=${PS1@P}
        prompt=${prompt//[$'\001\002']/}
        while [[ $prompt =~ $esc ]]; do prompt=${prompt/"${BASH_REMATCH[0]}"/}; done
    fi
    # Room left once the command's line (the prompt and " git_log") and the next prompt are counted
    room=$(( rows - (${#prompt} + 8 + cols - 1) / cols - (${#prompt} > 0 ? (${#prompt} + cols - 1) / cols : 1) ))
    while IFS= read -r line; do
        plain=$line # Without its colors, to measure; a line wider than the screen takes more rows
        while [[ $plain =~ $esc ]]; do plain=${plain/"${BASH_REMATCH[0]}"/}; done
        used=$(( (${#plain} + cols - 1) / cols ))
        (( used > 0 )) || used=1
        (( shown > 0 && used > room )) && break # Always at least one
        printf '%s\n' "$line"
        (( room -= used, shown++ ))
    done <<< "$out"
}

git_tracked() { # Toggles staging between "every change to tracked files" and empty; new files you added stay staged
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
    if [[ $status == *$'\n'[12]' '?[!.]' '* ]]; then # Tracked changes not staged yet: stage them, keeping the rest
        git add --update && echo "$branch Staged all tracked files."
    elif [[ $status == *$'\n'[12]' '[!.]* ]]; then # Everything is staged already: unstage it all, new files too
        # "git reset" also forgets a merge, cherry-pick or revert in progress; never do that from a toggle
        gitdir=$(git rev-parse --git-dir) || return
        if [ -e "$gitdir/MERGE_HEAD" ] || [ -e "$gitdir/CHERRY_PICK_HEAD" ] || [ -e "$gitdir/REVERT_HEAD" ]; then
            echo "$branch A merge, cherry-pick or revert is in progress; staging left alone."
            return 1
        fi
        git reset --quiet && echo "$branch Unstaged all files."
    elif [[ $status == *$'\n'[12?]' '* ]]; then # Only untracked files
        echo "$branch No changes to tracked files."
    else
        echo "$branch Working tree clean."
    fi
}

git_flagged() { # True if path $1 looks like a secret or junk. Sets REPLY to what to list (the path, or the junk
    # folder it is in) and kind to "secret" or "junk"; the caller declares kind as a local.
    local path=/$1 folder
    for folder in node_modules __pycache__ .cache .venv venv .pytest_cache .mypy_cache .ruff_cache .tox .idea; do
        if [[ $path == */"$folder"/* ]]; then
            REPLY=${path%%"/$folder/"*}/$folder/
            REPLY=${REPLY#/}
            kind=junk
            return
        fi
    done
    REPLY=$1
    case ${1##*/} in
        .env.example|.env.sample|.env.template|.env.dist) return 1 ;; # Meant to be committed
        .env|.env.*|*.pem|*.key|*.p12|*.pfx|*.ppk|*.jks|*.keystore|*.kdbx) kind=secret ;;
        id_rsa|id_dsa|id_ecdsa|id_ed25519|.netrc|.pgpass|.htpasswd|credentials.json|secrets.*) kind=secret ;;
        .DS_Store|Thumbs.db|desktop.ini|*.pyc|*.pyo|.*.sw?|*~|*.tmp|.*cache) kind=junk ;;
        *) return 1 ;;
    esac
}

git_commit_key() { # Waits for one of git_commit's prompt keys and sets REPLY to it (^Q for Ctrl+Q); 1 and 2 count only if $1 is set
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
            [12]) [ -z "$1" ] || return 0 ;;
            $'\x11') REPLY=^Q; return ;;
        esac
    done
}

git_commit() { # Commits what you staged, or everything if nothing is staged, offering to leave out secrets and junk
    # git_commit [message]: with a message, commits with it instead of opening the editor
    local record path key kind i color status old_trap tty_state skip= any= staged= conflict= without= tree=
    local message=()
    (( $# )) && message=(-m "$1")
    local last_new= last_added= red= yellow= off= both= keep=
    local new=() new_kinds=() added=() added_kinds=() added_paths=() added_path_kinds=()
    local found=() kinds=() excludes=() remove=()
    # One call: "? path" untracked, "1 XY ... path" / "2 XY ... path" changed (X staged, Y unstaged), "u ..." conflict
    while IFS= read -r -d '' record; do
        any=1
        if [ -n "$skip" ]; then skip=; continue; fi # The old path that follows a rename
        case $record in
            '? '*)
                if git_flagged "${record:2}" && [ "$REPLY" != "$last_new" ]; then
                    new+=("$REPLY"); new_kinds+=("$kind"); last_new=$REPLY
                fi ;;
            [12]' '*)
                [ "${record:2:1}" = . ] || staged=1
                [ "${record:0:1}" = 1 ] || skip=1
                path=${record#* * * * * * * * }
                if [ "${record:2:1}" = A ] && git_flagged "$path"; then # Only files this commit would add
                    added_paths+=("$path"); added_path_kinds+=("$kind")
                    [ "$REPLY" = "$last_added" ] || { added+=("$REPLY"); added_kinds+=("$kind"); last_added=$REPLY; }
                fi ;;
            'u '*) conflict=1 ;;
        esac
    done < <(git status --porcelain=v2 -z --untracked-files=all 2> /dev/null)
    # Nothing to do, a conflict, or not a repo: Git says so itself
    if [ -z "$any" ] || [ -n "$conflict" ]; then git commit "${message[@]}"; return; fi

    if [ -n "$staged" ]; then
        found=("${added[@]}"); kinds=("${added_kinds[@]}")
    else
        found=("${new[@]}"); kinds=("${new_kinds[@]}")
    fi
    if (( ${#found[@]} )); then
        # Secrets first in red, then junk in yellow; colors only when printing to a terminal
        [ -t 1 ] && red=$'\e[31m' yellow=$'\e[33m' off=$'\e[m'
        echo "Potentially unwanted files detected:"
        # With both groups found, each label says its key: 1 or 2 keeps that group and excludes only the other
        [[ " ${kinds[*]} " == *" secret "* && " ${kinds[*]} " == *" junk "* ]] && both=1
        for kind in secret junk; do
            [[ " ${kinds[*]} " == *" $kind "* ]] || continue
            if [ "$kind" = secret ]; then
                color=$red
                echo "[Secrets]${both:+ (press 1 to keep)}"
            else
                color=$yellow
                echo "[Junk]${both:+ (press 2 to keep)}"
            fi
            for i in "${!found[@]}"; do
                [ "${kinds[i]}" != "$kind" ] || printf '  %s%s%s\n' "$color" "${found[i]}" "$off"
            done
        done
        printf 'Exclude from this commit? [y/n] (a/q aborts) ' # Ctrl+Q and Ctrl+C abort too
        # The terminal keeps Ctrl+Q for itself (flow control); turn that off while asking, so it gets here
        tty_state=$(stty -g 2> /dev/null) && stty -ixon
        # Ctrl+C only leaves git_commit_key, so the terminal is put back below whichever key ends the wait.
        # It does nothing in the instant before or after that call, where "return" would leave git_commit.
        old_trap=$(trap -p INT)
        trap '[ "${FUNCNAME[0]}" != git_commit_key ] || { REPLY=^C; return; }' INT
        git_commit_key "$both"
        eval "${old_trap:-trap - INT}"
        [ -z "$tty_state" ] || stty "$tty_state"
        key=$REPLY
        echo "$key"
        case $key in
            [yY]) without=1 ;;
            1) without=1 keep=secret ;; # Exclude only the junk
            2) without=1 keep=junk ;; # Exclude only the secrets
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
            for i in "${!added_paths[@]}"; do # Everything flagged, minus the group being kept
                [ "${added_path_kinds[i]}" = "$keep" ] || remove+=("${added_paths[i]}")
            done
            tree=$(git write-tree) &&
                printf ':(top,literal)%s\0' "${remove[@]}" |
                git rm --cached --force --quiet --pathspec-from-file=- --pathspec-file-nul
        fi && git commit "${message[@]}"
        status=$?
        if (( status )) && [ -n "$tree" ]; then
            git read-tree "$tree" # Back to exactly what you had staged
        fi
    else # Nothing staged: stage everything, as "git add --all" would
        if [ -n "$without" ]; then
            for i in "${!found[@]}"; do # Everything flagged, minus the group being kept
                [ "${kinds[i]}" = "$keep" ] || excludes+=(":(top,literal,exclude)${found[i]}")
            done
            git add --all -- ':/' "${excludes[@]}"
        else
            git add --all
        fi && git commit "${message[@]}"
        status=$?
        if (( status )); then
            git reset --quiet # Back to nothing staged, as it was
        fi
    fi
    eval "${old_trap:-trap - INT}" # Ctrl+C behaves as it did before
    return $status
}

# In Vim's terminal (Vim sets VIM_TERMINAL), Ctrl+] types git_commit "" with the cursor between
# the quotes, replacing that key from ~/.inputrc, as Git's editor misbehaves inside Vim.
if [[ -n "$VIM_TERMINAL" && $- == *i* ]]; then
    bind '"\C-]": "\C-e\C-u git_commit \"\"\C-b"'
fi

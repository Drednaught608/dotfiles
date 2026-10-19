# Set the Bash settings for this OS
if [[ $OSTYPE == msys* || $OSTYPE == cygwin* ]]; then

    # Windows Aliases
    alias ls='ls --color=auto --show-control-chars'
    # Windows' own ssh rather than Git's: under Windows Terminal, Git's passes a Windows
    # SSH server's keys through as raw codes (;29;0;1;8;1_...) at the start of a session.
    # Git's own commands still use Git's ssh; this is only the ssh you type.
    alias ssh="${SYSTEMROOT//\\//}/System32/OpenSSH/ssh.exe"

    # open: opens each file or folder with its Windows app (a folder in Explorer), or a link
    # (https:, mailto:, shell:Downloads, ms-settings:...). Paths can be written either way,
    # 'C:\Users' (quoted, or Bash drops the \) or /c/Users. Explorer says nothing for a path
    # that doesn't exist, so that is an error here.
    # An open alias from an older version of this file would win over the function, so it goes.
    # "function open", not "open()": that would be read as the alias, and define explorer().
    unalias open 2> /dev/null
    function open {
        local arg path win status=0
        local link='^[A-Za-z][A-Za-z0-9+.-]+:' # A scheme and ":"; a drive letter is only one letter
        local unquoted='^[A-Za-z]:[^/\\]'      # C:Users: what Bash leaves of an unquoted C:\Users
        if (( $# == 0 )); then
            echo "usage: open <file, folder or link>..." >&2
            return 2
        fi
        for arg; do
            if [[ $arg =~ $link ]]; then
                explorer "$arg"
            elif path=$(cygpath -u -- "$arg" 2> /dev/null) && [ -e "$path" ]; then
                win=$(cygpath -wa -- "$path")
                if [[ $win == *,* ]]; then
                    # Explorer splits what it's given at commas, so PowerShell opens these
                    OPEN_PATH=$win powershell.exe -NoProfile -NonInteractive \
                        -Command 'Invoke-Item -LiteralPath $env:OPEN_PATH'
                else
                    explorer "$win"
                fi
            elif [[ $arg =~ $unquoted ]]; then
                echo "open: $arg: No such file or directory (Bash drops the \\ from an unquoted path; quote it: open '${arg:0:2}\\...')" >&2
                status=1
            else
                echo "open: $arg: No such file or directory" >&2
                status=1
            fi
        done
        return $status # Explorer's own status is 1 even when it worked, so it isn't used
    }

    # snip: Tab on its first argument offers your snippets (the folders in ~/.config/snip);
    # anywhere else, or when no snippet matches, Bash completes files here as usual
    _snip() {
        local d
        COMPREPLY=()
        (( COMP_CWORD == 1 )) || return
        for d in ~/.config/snip/*/; do
            [ -d "$d" ] && d=${d%/} && COMPREPLY+=("${d##*/}")
        done
        COMPREPLY=($(compgen -W "${COMPREPLY[*]}" -- "${COMP_WORDS[1]}"))
    }
    complete -o default -F _snip snip

    # Logged in over SSH, Windows' SSH server garbles some pasted text (like text with
    # escape codes in it) inside bracketed paste's start and end markers, and Bash then
    # waits for an end that never comes, frozen. So take a paste as plain typing here.
    if [ -n "$SSH_CONNECTION" ]; then
        bind 'set enable-bracketed-paste off'
    fi

    # Windows' own Vim (gVim or console) starts its terminal's Bash in a folder written the
    # Windows way (C:/Users/...); use the usual /c/Users/... instead, so the prompt shows ~
    # and $PWD matches $HOME
    if [[ $PWD == [A-Za-z]:/* ]]; then
        cd "$(cygpath -u "$PWD")"
    fi

elif [[ $OSTYPE == darwin* ]]; then

    # MacOS Aliases
    alias ls='ls -G'

elif [[ $OSTYPE == linux* ]]; then

    # Linux Aliases
    alias ls='ls --color=auto --show-control-chars'
    if command -v xdg-open > /dev/null; then
        alias open='xdg-open' # Like macOS's open: a file or folder in its app, or a web address
    fi

fi

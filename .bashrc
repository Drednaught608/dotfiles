# Exports / Settings
bind 'set bell-style none'
bind 'set page-completions off'
bind 'set completion-ignore-case on'
export HISTSIZE=
export HISTFILESIZE=
export HISTCONTROL=ignoreboth
export PROMPT_COMMAND='history -a'
export HISTIGNORE='history:clear:cls:ls:la:ll:cd:pwd:exit:logout:bg:fg:top:htop:uptime:df:free:micro:nano:vi:vim:nvim'
export PATH="$HOME/.local/bin:$HOME/.local/scripts:$PATH"

# Aliases
alias cls='clear'
alias rm='rm -d'
alias rn='mv'
alias ls='ls --color=auto --show-control-chars'
alias la='ls -A'
alias ll='ls -hAl'
alias grep='grep --color'
alias wc='wc --lines'
alias tldr='tldr -s'
alias diff='diff -u'
alias Git='git'
alias vi-='vi -c "setlocal buftype=nofile bufhidden=hide noswapfile" -'
alias vim-='vim -c "setlocal buftype=nofile bufhidden=hide noswapfile" -'
alias gvim-='gvim -c "setlocal buftype=nofile bufhidden=hide noswapfile" -'
alias vimplugins='ls -A1 ~/.vim/plugged 2>/dev/null | echo "$(wc -l) Vim Plugins"; ls -A1 ~/.vim/plugged 2>/dev/null'

# Normal Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Functions

git() { # Allows for dgit to trigger when in home directory
    if [[ "$PWD" = "$HOME" && "$1" != "clone" && "$1" != "config" ]] && command -v dgit &> /dev/null; then
        command dgit "$@"
    else
        command git "$@"
    fi
}

staging_toggle() { # Allows for adding & removing all from staging
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

# Source Bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Source local Bash settings if they exist
case $OSTYPE in
    msys*|cygwin*) os=win ;;
    darwin*)       os=mac ;;
    linux*)        os=linux ;;
esac
[ -z "$os" ] || [ ! -f ~/.local/bash/$os.bash ] || source ~/.local/bash/$os.bash
unset os
[ ! -f ~/.bash_aliases ] || source ~/.bash_aliases
[ ! -f ~/.bash_local ] || source ~/.bash_local

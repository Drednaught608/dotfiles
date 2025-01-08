# Exports / Settings
bind 'set bell-style none'
export HISTSIZE=
export HISTFILESIZE=
export HISTCONTROL=ignoredups
export PROMPT_COMMAND='history -a'
export HISTIGNORE='history:clear:cls'
if [[ '$OSTYPE' == 'msys' || '$OSTYPE' == 'cygwin' || '$OSTYPE' == 'mingw'* ]]; then
    echo -ne "\e]0;Bash\a"
fi

# Aliases
alias open='explorer'
alias cls='clear'
alias rm='rm -d'
alias rn='mv'
alias ls='ls --color=auto --show-control-chars'
alias la='ls -A'
alias ll='ls -hAl'
alias grep='grep --color'
alias wc='wc --lines'
alias tldr='tldr -s'
alias 'branch'='git branch --color=always | grep --color=never --line-buffered "\*"'
alias diff='diff -u'
alias Git='git'
alias yadm='yadm -C ~'
alias pdb='python -m pdb'
alias pdb3='python3 -m pdb'
alias vim-='vim -c "setlocal buftype=nofile bufhidden=hide noswapfile" -'
alias gvim-='gvim -c "setlocal buftype=nofile bufhidden=hide noswapfile" -'
alias vimplugins='ls -A1 ~/.vim/plugged 2>/dev/null | echo "$(wc -l) Vim Plugins"; ls -A1 ~/.vim/plugged 2>/dev/null'
alias vimupdate='~/.scripts/vim/sync_vim_plugins.sh'

# Normal Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Functions

git() { # Allows for yadm to trigger when in home directory
    if [ "$(pwd)" = "$HOME" ] && command -v yadm &> /dev/null; then
        command yadm "$@"
    else
        command git "$@"
    fi
}

# Source local bash settings if they exist
if [ -f ~/.bash_local ]; then
    source ~/.bash_local
fi

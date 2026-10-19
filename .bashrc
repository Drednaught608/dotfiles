# Commands run over SSH can read this too: give them PATH, then stop
export PATH="$HOME/.local/bin:$HOME/.local/scripts:$PATH"
[[ $- == *i* ]] || return 0

# Exports / Settings
bind 'set bell-style none'
bind 'set page-completions off'
bind 'set completion-ignore-case on'
export HISTSIZE=
export HISTFILESIZE=
export HISTCONTROL=ignoreboth
export PROMPT_COMMAND='history -a'
export HISTIGNORE='history:clear:cls:ls:la:ll:cd:pwd:exit:logout:bg:fg:top:htop:uptime:df:free:micro:nano:vi:vim:nvim'

# Aliases
alias cls='clear'
alias rm='rm -d'
alias rn='mv'
alias la='ls -A'
alias ll='ls -hAl'
alias grep='grep --color'
alias wc='wc -l'
alias tldr='tldr -s'
alias diff='diff -u'
alias Git='git'
alias vi-='vi -c "setlocal buftype=nofile bufhidden=hide noswapfile" -'
alias vim-='vim -c "setlocal buftype=nofile bufhidden=hide noswapfile" -'
alias gvim-='gvim -c "setlocal buftype=nofile bufhidden=hide noswapfile" -'
alias vimplugins='ls -A1 ~/.vim/plugged 2>/dev/null | echo "$(wc -l) Vim Plugins"; ls -A1 ~/.vim/plugged 2>/dev/null'

# Normal Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Source Bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Source os-specific & local Bash settings if they exist
[ ! -f ~/.local/bash/os_specific.bash ] || source ~/.local/bash/os_specific.bash
[ ! -f ~/.local/bash/git_functions.bash ] || source ~/.local/bash/git_functions.bash
[ ! -f ~/.bash_aliases ] || source ~/.bash_aliases
[ ! -f ~/.bash_local ] || source ~/.bash_local

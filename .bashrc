# Exports / Settings
set -o vi
bind 'set bell-style none'
export HISTSIZE=
export HISTFILESIZE=
export HISTCONTROL=ignoredups
export PROMPT_COMMAND='history -a'
echo -ne "\e]0;Bash\a"

# Aliases
alias open='explorer'
alias cls='clear'
alias rm='rm -d'
alias ls='ls --color=auto --show-control-chars'
alias la='ls -A'
alias ll='ls -hAl'
alias grep='grep --color'
alias wc='wc --lines'
alias tldr='tldr -s'
alias 'branch'='git branch --color=always | grep --color=never --line-buffered "\*"'

# Normal Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

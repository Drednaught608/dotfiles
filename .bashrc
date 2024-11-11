# Exports / Settings
set -o vi
bind 'set bell-style none'
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

# User Functions
#[ -f "/c/Users/Michael/bin/win-sudo/s/path.sh" ] && source "/c/Users/Michael/bin/win-sudo/s/path.sh"

# Normal Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Fully Featured Git Prompt
#if [ -f ~/.git-prompt.sh ]; then
#  . ~/.git-prompt.sh
#  PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w$(__git_ps1 " \[\033[1;31m\](%s)" )\[\033[00m\]\$ '
#else
#  PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
#fi

# Basic Fast Git Prompt
git_branch_name () {
  local xroot="$PWD"
  while [ ! -e "${xroot}/.git" ]; do
    local updir=${xroot%/*}
    if [ "$updir" == "$xroot" ]; then
      break
    fi
    xroot="$updir"
  done
  local xgit_dir="$xroot/.git"
  local worktree_tag
  local fline
  if [ -f "$xgit_dir" ]; then
    # if .git is a file it can be a worktree
    read fline < "$xgit_dir"
    xgit_dir="${fline#gitdir: }"
    worktree_tag=" (worktree)"
  fi
  if [ -f "$xgit_dir/HEAD" ]; then
    read fline < "$xgit_dir/HEAD"
    printf " \001\e[01;31m(\002${fline##*/}$worktree_tag)\001\002\e[0m"
  fi
}

#PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w$(git_branch_name " \[\033[1;31m\](%s)" )\[\033[00m\]\$ '

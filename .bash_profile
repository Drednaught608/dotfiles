# Login shells read this instead of ~/.bashrc: macOS's Terminal opens one, as do
# Git Bash and ssh. So load ~/.bashrc, when there's someone to type at it.

# macOS's own Bash: don't print "The default interactive shell is now zsh" at each start
export BASH_SILENCE_DEPRECATION_WARNING=1

case $- in *i*) . ~/.bashrc ;; esac

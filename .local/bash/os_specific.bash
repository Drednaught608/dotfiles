# Set the Bash settings for this OS
if [[ $OSTYPE == msys* || $OSTYPE == cygwin* ]]; then

    # Windows Aliases
    alias ls='ls --color=auto --show-control-chars'
    alias open='explorer'

elif [[ $OSTYPE == darwin* ]]; then

    # MacOS Aliases
    alias ls='ls -G'

elif [[ $OSTYPE == linux* ]]; then

    # Linux Aliases
    alias ls='ls --color=auto --show-control-chars'

fi

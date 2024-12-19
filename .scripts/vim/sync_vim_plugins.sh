#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\e[0;33m'
NC='\033[0m' # No Color

PLUGNUM="$(wc --lines ~/.vimplugins | grep -o '[0-9]*')"

VIM1="$HOME/.vim"

echo -e "\n${YELLOW}Starting sync of $PLUGNUM Vim plugins${NC}\n"
mkdir -p ~/.vim/pack/plugins/start/ ~/.vim/colors/

curl -fso temp_file https://raw.githubusercontent.com/Drednaught608/vim-habamax/refs/heads/master/colors/habamax.vim && mv temp_file "$VIM1/colors/habamax.vim"

counter=1
p="$HOME/.vimplugins"

while read p; do

    echo "========================================="
    echo -e "\n[${GREEN}PLUGIN $counter/$PLUGNUM${NC}: ${CYAN}$p${NC}]\n"

    DIR="${p##*/}"
    PATH1="$VIM1/pack/plugins/start"

    if [ -d "$PATH1/$DIR/.git" ]; then
        echo -ne "${CYAN}~/.vim:     ${NC}"
        git -C $PATH1/$DIR/ reset --hard HEAD >/dev/null
        git -C $PATH1/$DIR/ pull
        echo
    else
        echo -ne "${CYAN}~/.vim:     ${NC}"
        git -C $PATH1 clone https://github.com/$p.git
        echo
    fi

    ((counter++))

done < "$p"

echo "========================================="
echo -e "\n${YELLOW}Finished syncing of $PLUGNUM Vim plugins.${NC}\n"

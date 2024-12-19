#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\e[0;33m'
NC='\033[0m' # No Color

PLUGNUM="$(wc --lines ~/.vimplugins | grep -o '[0-9]*')"
grep ~/.vimplugins ""

VIM1="$HOME/.vim"
PATH1="$VIM1/pack/plugins/start"

echo -e "\n${YELLOW}Starting cleanup of unlisted Vim plugins${NC}\n"
mkdir -p ~/.vim/pack/plugins/start/ ~/vimfiles/pack/plugins/start/ ~/.scripts/vim/temp/

VIMLIST="$HOME/.scripts/vim/temp/plugin_list.txt"
ls -d "$PATH1"/*/ | awk -F'/' '{print $(NF-1)}' | sort > $VIMLIST

totalvimcounter=0

while read VIMLIST; do

    echo "========================================="
    echo -e "\n[${GREEN}~/.vim PLUGIN${NC}: ${CYAN}$VIMLIST${NC}]\n"

    PATH1="$VIM1/pack/plugins/start"
    MATCH="$(grep -c "$VIMLIST" ~/.vimplugins)"

    if [ $MATCH != 1 ]; then
        echo "Removing ~/.vim/pack/plugins/start/$VIMLIST/"
        rm -rf "$PATH1/$VIMLIST/"
        ((totalvimcounter++))
    else
        echo "Verified"
    fi
    echo

done < "$VIMLIST"

rm -rf ~/.scripts/vim/temp/

echo "========================================="
echo -e "\n${YELLOW}Finished cleanup run for $PLUGNUM Vim plugins.${NC}\n"
echo -e "Total plugins removed: $totalvimcounter\n"

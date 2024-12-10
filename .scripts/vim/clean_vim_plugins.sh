#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\e[0;33m'
NC='\033[0m' # No Color

PLUGNUM="$(wc --lines ~/.vimplugins | grep -o '[0-9]*')"
grep ~/.vimplugins ""

VIM1="$HOME/.vim"
VIM2="$HOME/vimfiles"
PATH1="$VIM1/pack/plugins/start"
PATH2="$VIM2/pack/plugins/start"

echo -e "\n${YELLOW}Starting cleanup of unlisted Vim plugins${NC}\n"
mkdir -p ~/.vim/pack/plugins/start/ ~/vimfiles/pack/plugins/start/ ~/.scripts/vim/temp/

VIMLIST="$HOME/.scripts/vim/temp/.vim_plugin_list.txt"
VIMFILESLIST="$HOME/.scripts/vim/temp/vimfiles_plugin_list.txt"
ls -d "$PATH1"/*/ | awk -F'/' '{print $(NF-1)}' | sort > $VIMLIST
ls -d "$PATH2"/*/ | awk -F'/' '{print $(NF-1)}' | sort > $VIMFILESLIST

totalvimcounter=0
vimlistcounter=0

while read VIMLIST; do

    echo "========================================="
    echo -e "\n[${GREEN}~/.vim PLUGIN${NC}: ${CYAN}$VIMLIST${NC}]\n"

    PATH1="$VIM1/pack/plugins/start"
    MATCH="$(grep -c "$VIMLIST" ~/.vimplugins)"

    if [ $MATCH != 1 ]; then
        echo "Removing ~/.vim/pack/plugins/start/$VIMLIST/"
        rm -rf "$PATH1/$VIMLIST/"
        ((vimlistcounter++))
        ((totalvimcounter++))
    else
        echo "Verified"
    fi
    echo

done < "$VIMLIST"

vimfileslistcounter=0

while read VIMFILESLIST; do

    echo "========================================="
    echo -e "\n[${GREEN}~/vimfiles PLUGIN${NC}: ${CYAN}$VIMFILESLIST${NC}]\n"

    PATH1="$VIM1/pack/plugins/start"
    MATCH="$(grep -c "$VIMFILESLIST" ~/.vimplugins)"

    if [ $MATCH != 1 ]; then
        echo "Removing ~/vimfiles/pack/plugins/start/$VIMFILESLIST/"
        rm -rf "$PATH2/$VIMFILESLIST/"
        ((vimfileslistcounter++))
        ((totalvimcounter++))
    else
        echo "verified"
    fi
    echo

done < "$VIMFILESLIST"

rm -rf ~/.scripts/vim/temp/

echo "========================================="
echo -e "\n${YELLOW}Finished cleanup run for $PLUGNUM Vim plugins.${NC}\n"
echo -e "${YELLOW}STATS:${NC}"
echo -e "Number of ~/.vim     plugins removed: $vimlistcounter"
echo -e "Number of ~/vimfiles plugins removed: $vimfileslistcounter"
echo -e "Total plugins removed:                $totalvimcounter\n"
#!/usr/bin/env bash
# install.sh - set up these dotfiles on a new machine (Linux, macOS, or Git
# Bash on Windows):
#
#   1. fetch dgit from this repo into ~/.local/scripts
#   2. dgit clone the dotfiles over HTTPS (public repo, so no key needed),
#      then hard-reset $HOME to origin/main
#   3. point origin at SSH, then run update_setup: update_ssh fixes ~/.ssh
#      permissions and checks the key authenticates to GitHub (with no
#      ~/.ssh/id_ed25519, it first derives the key from your master password),
#      and update_terminal installs the fonts and, on Windows, links Windows
#      Terminal's settings
#
# Files the reset overwrites, and any previous dgit repo, are moved into
# ~/.local/share/dotfiles first. This is for a new machine: on one already set
# up, it would reset your dotfiles to the last push. To redo just the setup in
# step 3, run update_setup instead.
#
#   curl -fsSL https://raw.githubusercontent.com/Drednaught608/dotfiles/main/.github/install.sh | bash

set -euo pipefail

HTTPS_URL=https://github.com/Drednaught608/dotfiles.git
SSH_URL=git@github.com:Drednaught608/dotfiles.git
RAW=https://raw.githubusercontent.com/Drednaught608/dotfiles/main
DGIT=$HOME/.local/scripts/dgit
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
DGIT_DIR=${DGIT_DIR:-$DATA/dgit}
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=$DATA/dotfiles/backup-$STAMP

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null || die "Git is not installed"
if command -v curl >/dev/null; then fetch() { curl -fsSL "$1" -o "$2"; }
elif command -v wget >/dev/null; then fetch() { wget -qO "$2" "$1"; }
else die "need curl or wget to download dgit"
fi

say "Downloading dgit to $DGIT"
mkdir -p "${DGIT%/*}"
fetch "$RAW/.local/scripts/dgit" "$DGIT.tmp" || die "could not download dgit"
mv "$DGIT.tmp" "$DGIT"
chmod +x "$DGIT"

# Start fresh: move any previous dgit repo aside rather than deleting it.
if [ -e "$DGIT_DIR" ]; then
  say "Moving existing $DGIT_DIR to $BACKUP/dgit"
  mkdir -p "$BACKUP"
  mv "$DGIT_DIR" "$BACKUP/dgit"
fi

# Skip the global gitconfig for the clone: if one is already in place (a
# rerun, say), its insteadOf would turn this HTTPS URL back into SSH.
say "Cloning $HTTPS_URL into $HOME"
GIT_CONFIG_GLOBAL=/dev/null "$DGIT" clone "$HTTPS_URL"

# dgit clone keeps any existing file that differs from the repo; back those
# up, then reset so $HOME matches origin/main exactly.
changed=$("$DGIT" diff --name-only)
if [ -n "$changed" ]; then
  say "Backing up files that will be replaced to $BACKUP"
  while IFS= read -r f; do
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp -p "$HOME/$f" "$BACKUP/$f"
  done <<< "$changed"
fi

say "Resetting to origin/main"
"$DGIT" reset --hard origin/main

# Push over SSH from now on (the dotfiles .gitconfig rewrites GitHub HTTPS
# URLs to SSH anyway; this makes it explicit).
"$DGIT" remote set-url origin "$SSH_URL"

# The setup that follows (SSH key, fonts, Windows Terminal) is update_setup's, so
# it can be redone any time without all this. Each step says what to fix itself.
# Its input is empty: run as "curl ... | bash", the rest of this script is still
# waiting there, and a program reading it (ssh does) would swallow it. The master
# password, if it's asked for, is read from the terminal, not from there.
"$HOME/.local/scripts/update_setup" < /dev/null ||
  warn "some of the setup didn't finish; fix what's described above, then run: update_setup"

say "Done. Open a new shell (or run: source ~/.bashrc) to pick up the dotfiles."

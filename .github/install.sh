#!/usr/bin/env bash
# install.sh - set up these dotfiles on a new machine (Linux, macOS, or Git
# Bash on Windows):
#
#   1. fetch dgit from this repo into ~/.local/scripts
#   2. dgit clone the dotfiles over HTTPS (public repo, so no key needed),
#      then hard-reset $HOME to origin/main
#   3. point origin at SSH and, if ~/.ssh/id_ed25519 exists, run updatessh
#      to fix its permissions and check it authenticates to GitHub
#
# Files the reset overwrites, and any previous dgit repo, are moved into
# ~/.local/share/dotfiles first.
#
#   curl -fsSL https://raw.githubusercontent.com/Drednaught608/dotfiles/main/.github/install.sh | bash

set -euo pipefail

HTTPS_URL=https://github.com/Drednaught608/dotfiles.git
SSH_URL=git@github.com:Drednaught608/dotfiles.git
RAW=https://raw.githubusercontent.com/Drednaught608/dotfiles/main
KEY=$HOME/.ssh/id_ed25519
DGIT=$HOME/.local/scripts/dgit
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
DGIT_DIR=${DGIT_DIR:-$DATA/dgit}
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=$DATA/dotfiles/backup-$STAMP

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null || die "'git' is not installed"
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

# Push over SSH from now on (the dotfiles' .gitconfig rewrites GitHub HTTPS
# URLs to SSH anyway; this makes it explicit).
"$DGIT" remote set-url origin "$SSH_URL"

if [ -f "$KEY" ]; then
  say "Setting SSH permissions"
  "$HOME/.local/scripts/updatessh" || warn "the SSH check failed; fix it, then run: updatessh"
else
  warn "no SSH key at $KEY, so pulling and pushing the dotfiles won't work yet.
  Copy your key pair (id_ed25519 and id_ed25519.pub) into ~/.ssh, or create one
  with 'ssh-keygen -t ed25519' and add the .pub at https://github.com/settings/keys,
  then run: updatessh"
fi

say "Done. Open a new shell (or run: source ~/.bashrc) to pick up the dotfiles."

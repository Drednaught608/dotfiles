# dotfiles

My dotfiles, managed with [`dgit`](../.local/scripts/dgit): a bare Git repo whose work tree is `$HOME`.

## Install

You need `git` and `curl` (or `wget`). The repo is cloned over HTTPS, so no SSH key is needed to install; one is needed later to pull and push.

**Linux / macOS / Git Bash on Windows:**

```bash
curl -fsSL https://raw.githubusercontent.com/Drednaught608/dotfiles/main/.github/install.sh | bash
```

**Windows PowerShell** (runs the same script through Git for Windows' bash):

```powershell
& "$env:ProgramFiles\Git\bin\bash.exe" -c "curl -fsSL https://raw.githubusercontent.com/Drednaught608/dotfiles/main/.github/install.sh | bash"
```

The [install script](install.sh):

1. Downloads `dgit` to `~/.local/scripts/dgit`.
2. Runs `dgit clone https://github.com/Drednaught608/dotfiles.git`, then `dgit reset --hard origin/main` so `$HOME` matches the repo exactly.
3. Switches `origin` to `git@github.com:Drednaught608/dotfiles.git` for pushing.
4. Runs `update_ssh` (below) on your existing `~/.ssh/id_ed25519`, or, if there isn't one, `update_ssh --derive` to create it from your master password.
5. On Windows, runs `update_terminal --auto` (below) so Windows Terminal uses the dotfiles settings.

Before the reset, any existing file that would be overwritten is copied to `~/.local/share/dotfiles/backup-<timestamp>/`, and an existing dgit repo is moved there too, not deleted.

## SSH key

Either copy your key pair (`id_ed25519` and `id_ed25519.pub`) into `~/.ssh` and run `update_ssh`, or derive the key from your master password:

```bash
update_ssh --derive
```

The same password always gives the same key, on any machine, so there's nothing to copy. If `~/.ssh/id_ed25519` is already a different key, `--derive` refuses to touch it; `update_ssh --derive --force` replaces it, keeping the old one as `id_ed25519.old-<timestamp>`.

The key's 32-byte Ed25519 seed is PBKDF2-HMAC-SHA512 of the password, with 3,000,000 iterations and, as salt, the first 8 bytes of SHA-256 of `dgit ssh v1 Drednaught608`. Any tool that computes that recovers the key. Those values are fixed for good, and `update_ssh` checks a known answer before every derive, so a changed `openssl` can't quietly produce a different key. The password is passed to `openssl` on stdin, never as an argument. Your public key is published on GitHub, so anyone can try guesses offline: use a long password. On macOS, `--derive` needs OpenSSL 3 installed (the built-in `openssl` is LibreSSL); otherwise copy in an existing key.

`update_ssh` sets `~/.ssh` permissions so ssh accepts the key: `700` for the directory, `600` for private keys and `config`, and `644` for `.pub` and `known_hosts`. On Windows it also sets owner-only ACLs with `icacls`, which Windows OpenSSH requires. Then it checks that the key authenticates to GitHub. If GitHub doesn't accept it, it tells you the key is either the wrong one (for a derived key, a mistyped password) or a new one, and prints the public key to add at <https://github.com/settings/keys>, as both an Authentication and a Signing key.

## Windows Terminal

Windows Terminal's settings live in [`~/.config/windows-terminal/settings.json`](../.config/windows-terminal/settings.json), next to the files they use: the Bash profile's background image (`japan.jpg`) and icon (`bash.png`), and the JetBrains Mono NL font (see [CREDITS.md](../.config/windows-terminal/CREDITS.md) for their sources and licences). The settings refer to the images as `%USERPROFILE%\.config\windows-terminal\...`, which works on any machine. To make Windows Terminal use all of this, run:

```bash
update_terminal          # link each install the way you chose (as --auto if you haven't yet)
update_terminal --auto   # or -a: choose for me: file links if Developer Mode is on, else live
update_terminal --file   # or -f: choose file links: each install's settings.json
update_terminal --live   # or -l: choose live: each install's whole settings folder
update_terminal --choice # or -c: show your choice and how each install is linked
update_terminal --path   # or -p: show each installed Windows Terminal's settings folder
```

It covers each installed Windows Terminal (the normal and Preview versions, and Scoop's portable installs); versions that aren't installed are skipped. Either way, Windows Terminal reads and saves the dotfiles `settings.json`, so changes made in its Settings show up as changes to commit. Close every Windows Terminal window and open it again afterwards; opening another window isn't enough, because it joins the one already running.

`--file` and `--live` save that as your choice, for this machine only, in `~/.local/share/dotfiles/terminal-link`. `--auto` (what the installer runs) chooses for you and saves it: file links if Developer Mode is on, else live. Plain `update_terminal` keeps to the saved choice, or chooses as `--auto` if nothing is saved yet. If file links are your choice but Developer Mode has since been turned off, so none can be made, a plain run links live for now and says so, keeping file links as your choice; once Developer Mode is back on, the next plain run switches back. The output starts with your choice, `[file mode]` or `[live mode]`, and why; then a line per install (linked, unchanged or switched) and per font; then a one-line summary of what changed.

The two differ in when a running Windows Terminal notices a change, since it only watches its own settings folder for one:

| | `update_terminal --file` | `update_terminal --live` |
|---|---|---|
| Links | `settings.json` (a file link) | the whole settings folder (a directory junction) |
| A change, from its Settings, a `dgit pull` or an edit, shows up | after a full restart | at once |
| Needs | Developer Mode (Settings > System > For developers) | nothing; but no program may have that folder open while it's set up |
| Windows Terminal's own files (remembered windows and the like) | stay in its folder | sit in `~/.config/windows-terminal`, untracked |

Running it with the other option switches over, and anything it replaces is kept as `<name>.bak-<timestamp>`. Run it again if a reinstall resets Windows Terminal's settings folder.

It also installs the fonts in that folder (`*.ttf`, `*.otf`) for your user only, which needs no administrator rights: each is copied into your own fonts folder and registered under `HKCU`, the way Windows does when you choose "Install", and fonts already installed are left alone. To use another font, put its file in the folder, run `update_terminal`, and set it in the settings.

## Usage

```bash
dgit status
dgit add ~/.vimrc
dgit commit -m "Update vimrc"
dgit push
```

Run `dgit help` for more.

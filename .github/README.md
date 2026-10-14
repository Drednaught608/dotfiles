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
5. On Windows, runs `update_terminal` (below) so Windows Terminal uses the dotfiles' settings.

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

Windows Terminal's settings live in [`~/.config/windows-terminal/settings.json`](../.config/windows-terminal/settings.json). To make Windows Terminal use them, run:

```bash
update_terminal
```

It replaces the `settings.json` of each installed Windows Terminal (the normal and Preview versions, and Scoop's portable installs) with a symbolic link to the dotfiles' file, keeping the old one as `settings.json.bak-<timestamp>`; versions that aren't installed are skipped. From then on, changes made in Windows Terminal's settings are saved straight into the dotfiles. It uses a symbolic link because Windows Terminal saves by replacing the file, and so does `git`, which would silently split a hard link into two copies. Making a symbolic link without administrator rights needs Developer Mode (Settings > System > For developers). Run it again if a reinstall resets Windows Terminal's settings.

## Usage

```bash
dgit status
dgit add ~/.vimrc
dgit commit -m "Update vimrc"
dgit push
```

Run `dgit help` for more.

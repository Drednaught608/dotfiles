# dotfiles

My dotfiles, managed with [`dgit`](../.local/scripts/dgit): a bare Git repo whose work tree is `$HOME`. The scripts and shell functions that come with them are in [SCRIPTS.md](SCRIPTS.md).

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

The [install script](install.sh) clones the dotfiles into `$HOME`, backing up any file it would overwrite to `~/.local/share/dotfiles/backup-<timestamp>/`. Then it sets up your SSH key, installs the fonts and, on Windows, points Windows Terminal at the dotfiles settings.

It's for a new machine: on one already set up, it would reset your dotfiles to the last push. To redo just the setup, run:

```bash
update_setup
```

## SSH key

Pulling and pushing need an SSH key, and installing sets one up. Either copy your key pair (`id_ed25519` and `id_ed25519.pub`) into `~/.ssh` and run `update_ssh`, or derive the key from your master password, which gives the same key on any machine:

```bash
update_ssh --derive
```

If GitHub doesn't know the key yet, `update_ssh` prints it to add at <https://github.com/settings/keys>. See [update_ssh](SCRIPTS.md#update_ssh) for the details.

## Using dgit

`dgit` is Git for your home folder. Everything there is ignored unless you add it, so `dgit status` shows only the files you track. In your home folder, plain `git` runs `dgit` too.

```bash
dgit status
dgit add ~/.vimrc
dgit commit -m "Update vimrc"
dgit push
```

Run `dgit help` for more, or see [dgit](SCRIPTS.md#dgit).

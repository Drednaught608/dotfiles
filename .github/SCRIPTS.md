# Scripts

The scripts that come with the dotfiles live in [`~/.local/scripts`](../.local/scripts), which `.bashrc` puts on your `PATH`. Each one prints its own usage with `--help`. Shell functions live in [`~/.local/bash`](../.local/bash), which `.bashrc` loads.

- [dgit](#dgit): the dotfiles repo
- [install.sh](#installsh): set up a new machine
- [update_setup](#update_setup): redo the setup after installing
- [update_ssh](#update_ssh): the SSH key
- [update_terminal](#update_terminal): Windows Terminal's settings and the fonts
- [snip](#snip): file snippets for new projects
- [Git keys and functions](#git-keys-and-functions)
- [Other shell additions](#other-shell-additions)

## dgit

[`dgit`](../.local/scripts/dgit) runs Git against your home folder. Its repo is a bare one in `~/.local/share/dgit` (or `$DGIT_DIR`), with `$HOME` as the work tree.

```bash
dgit init            # create the repo
dgit clone <url>     # clone dotfiles and check them out into $HOME
dgit add <path>...   # start tracking files (everything else is ignored)
dgit <git args...>   # any other git command, run against $HOME
dgit test            # run dgit's test suite
```

Everything in `$HOME` is ignored unless you add it, so `dgit status` shows only the files you track. Adding a file is the opt-in, so `dgit add` stages it even past an ignore rule. Paths can be relative or absolute, but any path outside `$HOME` is refused, and so is `$HOME` itself. In your home folder, plain `git` runs `dgit` (see [Git keys and functions](#git-keys-and-functions)).

It refuses anything that could reach all of `$HOME`:
- `dgit clean`, and `dgit stash --all`.
- `dgit add -A` stages only edits and deletions of files you already track.
- `dgit rm` won't delete a file that belongs to another project's Git repo in your home folder; it only stops tracking it (`dgit rm --cached`).

It also never overwrites a file you have that the repo doesn't track:
- `dgit clone` writes out only the files missing here, then lists the ones where yours differ, to review with `dgit diff`.
- `dgit pull`, `checkout`, `merge` and the like stop rather than replace an untracked or ignored file.

A shell alias (`!...` in `.gitconfig`) runs without the repo, as it could run anything.

`dgit test` runs its test suite against throwaway home folders in a temp folder. It runs `dgit` with the Bash you start it with, so on a Mac `/bin/bash ~/.local/scripts/dgit test` tests it under the built-in Bash 3.2. Section times come from Bash 5's clock, or from `perl` on older Bash, or in whole seconds if there's no `perl`.

## install.sh

[`install.sh`](install.sh) sets up a new machine (see the [README](README.md#install) for the command):

1. Downloads `dgit` to `~/.local/scripts/dgit`.
2. Runs `dgit clone https://github.com/Drednaught608/dotfiles.git`, then `dgit reset --hard origin/main` so `$HOME` matches the repo exactly.
3. Switches `origin` to `git@github.com:Drednaught608/dotfiles.git` for pushing.
4. Runs [`update_setup`](#update_setup).

Before the reset, any existing file that would be overwritten is copied to `~/.local/share/dotfiles/backup-<timestamp>/`, and an existing dgit repo is moved there too, not deleted.

It's for a new machine: on one already set up, it would reset your dotfiles to the last push.

## update_setup

[`update_setup`](../.local/scripts/update_setup) redoes the setup that follows installing, for example after changing the fonts. It's safe to run any time, and never touches the dotfiles repo or your files in it:

1. [`update_ssh`](#update_ssh) on your existing `~/.ssh/id_ed25519`, or, if there isn't one, `update_ssh --derive` to create it from your master password.
2. [`update_terminal`](#update_terminal), which installs the fonts and, on Windows, makes Windows Terminal use the dotfiles settings.

To redo just one step, run that script instead.

## update_ssh

[`update_ssh`](../.local/scripts/update_ssh) sets up the SSH key that pulling and pushing need. Either copy your key pair (`id_ed25519` and `id_ed25519.pub`) into `~/.ssh` and run `update_ssh`, or derive the key from your master password:

```bash
update_ssh                   # fix permissions and check the key
update_ssh --derive          # create the key from your master password
update_ssh --derive --force  # same, replacing a different existing key
update_ssh --server          # install and turn on an SSH server, key-only; if one is running, offer to turn it off
```

The same password always gives the same key, on any machine, so there's nothing to copy. If `~/.ssh/id_ed25519` is already a different key, `--derive` refuses to touch it; `--force` replaces it, keeping the old one as `id_ed25519.old-<timestamp>`.

The key's 32-byte Ed25519 seed is PBKDF2-HMAC-SHA512 of the password, with 3,000,000 iterations and, as salt, the first 8 bytes of SHA-256 of `dgit ssh v1 Drednaught608`. Any tool that computes that recovers the key. Those values are fixed for good, and `update_ssh` checks a known answer before every derive, so a changed `openssl` can't quietly produce a different key. The password is passed to `openssl` on stdin, never as an argument. Your public key is published on GitHub, so anyone can try guesses offline: use a long password. On macOS, `--derive` needs OpenSSL 3 installed (the built-in `openssl` is LibreSSL); otherwise copy in an existing key.

`update_ssh` sets `~/.ssh` permissions so ssh accepts the key: `700` for the directory, `600` for private keys and `config`, and `644` for `.pub` and `known_hosts`. On Windows it also sets owner-only ACLs with `icacls`, which Windows OpenSSH requires. Then it checks that the key authenticates to GitHub. If GitHub doesn't accept it, it tells you the key is either the wrong one (for a derived key, a mistyped password) or a new one, and prints the public key to add at <https://github.com/settings/keys>, as both an Authentication and a Signing key.

The keys allowed to log in to a machine over SSH are in [`~/.ssh/authorized_keys`](../.ssh/authorized_keys), one per line, as the text of each `.pub` file; the end of each line is a comment saying whose key it is. It's part of the dotfiles, and the SSH server reads it there by default, so on Linux and macOS a key you add or remove works on each machine as soon as it pulls. A key added another way (by `ssh-copy-id`, say) shows up as a change to commit.

`update_ssh --server` deals with the SSH server and nothing else. If one is installed, on or off, and its setup (below) isn't up to date, it brings it up to date without asking, and that's all; run it again to turn the server on or off. Once it's up to date, or if there's no server, it asks, with `[y/n]`, depending on what's here:

| Here | It asks |
|---|---|
| A server is running (something answers on port 22) | `Turn it off?` Yes stops it and keeps it from starting with the computer, but leaves it installed. |
| A server is installed, but off | `Turn it on?` |
| No server | `Install one and turn it on?` |

Turning one on sets it to start with the computer, then sets it up as below: key-only, reading your keys. What that installs or turns on:

- **Windows:** the OpenSSH Server feature, its `sshd` service, and two firewall rules for port 22: from anyone on a Private network (your home network, so you can still connect by its local name if Tailscale is down), and from Tailscale's addresses on any network. Strangers on Public networks, like café Wi-Fi, can't reach it. That relies on your home network being set to Private (Settings > Network & internet > your connection).
- **macOS:** Remote Login, with `systemsetup`. macOS may want your terminal app to have Full Disk Access for that (System Settings > Privacy & Security); otherwise turn on Remote Login in System Settings > General > Sharing.
- **Linux:** the `openssh-server` package (`openssh` on Arch), through `apt`, `dnf` or `pacman`, and its systemd service. Another package manager, or no systemd, is an error that says to install it yourself.

The SSH server's setup:

- **Key-only logins.** Once there's a key to log in with, the server is set never to accept a password (`PasswordAuthentication no`, `KbdInteractiveAuthentication no`). On Linux and macOS that's a file of its own, `/etc/ssh/sshd_config.d/01-dotfiles-keys-only.conf`, written with `sudo`; on Windows it's the first lines of `C:\ProgramData\ssh\sshd_config`. It's only written when it isn't in place already, and the server's own check (`sshd -t`) has to pass first, or the change is undone. Then the running server is reloaded (on macOS, which starts the server for each login, there's nothing to reload). If `sshd_config` doesn't read `sshd_config.d`, it tells you the line to add.
- **Linux and macOS:** the server ignores your keys if your home folder can be written by others, so that's fixed, and on SELinux systems `~/.ssh` is relabelled.
- **Windows:** for an account in the Administrators group, the server reads `C:\ProgramData\ssh\administrators_authorized_keys` instead (as its `sshd_config` says by default), so `authorized_keys` is copied there, limited to Administrators and SYSTEM, as the server requires. It's a copy, so after your keys change it needs copying again. Without admin rights that file can't even be read, so `update_ssh` keeps a record of the last copy it made (`~/.local/share/dotfiles/administrators_authorized_keys`): when your keys match it, and the server's copy is still there, the same size, it's up to date.
- **Windows, the shell:** an SSH login gets Bash, Git's `bin\bash.exe` (the launcher, which sets `PATH` up as the Git Bash window does), instead of `cmd`. That's the server's `DefaultShell` in the registry (`HKLM\SOFTWARE\OpenSSH`), for every account that logs in over SSH. `scp` into the machine goes through it too, running Git's own `scp`; `sftp` doesn't.

Who does it:

- **Linux and macOS:** plain `update_ssh` sets up whatever SSH server is here, on or off, with `sudo`, only for what isn't in place yet; `--server` does too, when it turns one on. On macOS the server is always installed, so it's set up before you turn on Remote Login. After installing a server some other way, run `update_ssh` again.
- **Windows:** only `--server`, since all of it takes admin rights, and plain `update_ssh` never asks for them, so installing the dotfiles takes no UAC prompt. Instead it says when the server is out of date (after your keys change, say) and to run `update_ssh --server`, which brings it up to date. Each `--server` run that changes something takes one UAC prompt, with Windows' `sudo` or in a terminal opened as administrator, whether it updates, installs, or turns the server on or off; turning one on or off also brings its setup up to date in that same prompt.

Without admin rights, it says what still needs doing and to run it again.

## update_terminal

Windows Terminal's settings live in [`~/.config/windows-terminal/settings.json`](../.config/windows-terminal/settings.json), next to the images they use: the Bash profile's background image (`japan.jpg`) and icon (`bash.png`) (see [CREDITS.md](../.config/windows-terminal/CREDITS.md) for their sources and licences). The settings refer to the images as `%USERPROFILE%\.config\windows-terminal\...`, which works on any machine. Its font, JetBrains Mono NL, is kept with its licence in [`~/.config/fonts`](../.config/fonts) (see its [CREDITS.md](../.config/fonts/CREDITS.md)), since gVim uses it too; the settings name it, `JetBrains Mono NL`, rather than giving a path. To make Windows Terminal use all of this, run [`update_terminal`](../.local/scripts/update_terminal):

```bash
update_terminal          # link each install's settings folder to the dotfiles one
update_terminal --path   # or -p: show each installed Windows Terminal's settings folder
```

It covers each installed Windows Terminal (the normal and Preview versions, and Scoop's portable installs); versions that aren't installed are skipped. Each one's settings folder becomes a directory junction to `~/.config/windows-terminal`, which needs no administrator rights or Developer Mode. Windows Terminal then reads and saves the dotfiles `settings.json`, so changes made in its Settings show up as changes to commit. And since it watches that folder, it picks up a change at once, whether from its Settings, a `dgit pull` or an edit. Its own files (`state.json`: remembered windows and the like) sit there too, untracked.

Close every Windows Terminal window and open it again after linking; opening another window isn't enough, because it joins the one already running. No program may have its settings folder open while it's linked (an editor, an Explorer window, Windows Terminal). The folder it replaces is kept as `<name>.bak-<timestamp>`. Run it again if a reinstall resets Windows Terminal's settings folder.

It also installs the fonts in `~/.config/fonts` (`*.ttf`, `*.otf`) for your user only, which needs no administrator rights, so gVim can use them too. On Windows each is copied into your own fonts folder and registered under `HKCU`, the way Windows does when you choose "Install". On Linux they go in `~/.local/share/fonts` and fontconfig's cache is refreshed; on macOS they go in `~/Library/Fonts`. There, with no Windows Terminal, installing the fonts is all `update_terminal` does. Fonts already installed are left alone. To use another font, put its file in the folder, run `update_terminal`, and set it in the settings.

## snip

[`snip`](../.local/scripts/snip) keeps files you start projects with, in `~/.config/snip`: each folder there is a snippet, and its files are what it creates. Anything with a `/` is a path instead, naming one file or folder in there: `makefile/Makefile`, or `./LICENSE` for a file at the top of `~/.config/snip`. Files at the top aren't snippets, so `snip` doesn't list them, but `snip .` does.

```bash
snip                                  # list your snippets (-l, --list)
snip .                                # list everything at the top of ~/.config/snip, files too
snip -l makefile/src                  # list what's in a snippet, or a folder in it, like ls
snip makefile                         # copy the makefile snippet's files here
snip makefile/Makefile                # copy just that file (or folder) here; ./LICENSE for one at the top
snip makefile --add Makefile build.sh # add files (or folders) to it, making it if new (-a)
snip makefile/src --add main.c        # add them to that folder instead; . for the top
snip makefile --delete                # delete it (-d)
snip makefile/build.sh --delete       # delete just that file or folder
snip . --delete                       # delete everything in ~/.config/snip, after asking
snip --track                          # stage ~/.config/snip in dgit, to commit (-t)
```

Nothing is overwritten unless you add `-f` (`--force`), as in `snip makefile -f` or `snip -f makefile --add Makefile`. Copying skips each file that's already in the current directory and copies the rest, then lists what it `Skipped:` and `Created:`. `--add` won't replace a file or folder that's already there. With `-f`, both replace what's there.

The snippets are part of the dotfiles, but `--add` and `--delete` only change the files; run `snip --track` when you want to commit them. It stages every file in `~/.config/snip` in `dgit`, including any a snippet's own `.gitignore` would ignore (since that's part of the snippet), with executable files as executable, and the removal of any snippets you've deleted.

## Git keys and functions

[`git_functions.bash`](../.local/bash/git_functions.bash) adds Git shortcuts, each run by a key (set in [`.inputrc`](../.inputrc)) or by name. The key clears the command line and runs it.

| Key | Function | What it does |
|---|---|---|
| Ctrl+O | `git_status` | short status, with the branch and untracked files |
| Ctrl+T | `git_tracked` | stage every change to tracked files; press again to unstage everything |
| Ctrl+] | `git_commit` | commit what's staged, or everything if nothing is |
| Ctrl+G | `git_diff` | what `git_commit` would commit: what's staged, or, if nothing is, all your changes since the last commit, new files included; while resolving conflicts, just the conflicted files |
| Ctrl+H | `git_log` | recent commits as a graph, as many as fit on screen |
| Ctrl+/ | `git_branches` | all branches, local and remote, with their upstreams |
| Ctrl+R | `git_fetch` | fetch, following a change to a remote's default branch |
| Ctrl+P | `git_sync` | push if you have unpushed commits, otherwise pull |

- **`git_commit [message]`** commits with that message instead of opening the editor. Before committing, it lists files that look like secrets (`.env`, keys, credentials) or junk (`node_modules/`, `.DS_Store`, caches) and offers to leave them out. In Vim's terminal, where Git's editor misbehaves, Ctrl+] types `git_commit ""` for you to fill in the message instead.
- **`git_log [count]`** shows that many commits instead.
- **`git`** itself is a function: in your home folder it runs `dgit`, except for `git clone`, `git config` and Git's own help.

`.gitconfig` adds three aliases:

```bash
git alias    # list your aliases
git amend    # commit --amend
git mode     # the mode of each new file, and mode changes, in what's staged
```

## Other shell additions

[`os_specific.bash`](../.local/bash/os_specific.bash) adds, for each system:

- **`open <file, folder or link>...`** opens each in its app: a folder in Explorer, Finder or the file manager, a link in the browser. On Windows it's a function that also takes `C:\...` paths (quoted) and links like `shell:Downloads` or `ms-settings:`, and says so when a path doesn't exist. On macOS it's the built-in `open`; on Linux it runs `xdg-open`.
- **`ls`** with colors.
- On Windows, a Bash started by Windows' own Vim in a `C:/...` folder switches to the `/c/...` form, so the prompt shows `~`.

# Rheinard's dotfiles

A bare git repo in `~/.cfg` whose work tree is `$HOME`. The `config` alias
(defined in `.config/zsh/configs/pre/00-init.zsh`) is `git` for these files.
Based on https://www.atlassian.com/git/tutorials/dotfiles.

## Install on a new Mac

```bash
curl -fsSL https://raw.githubusercontent.com/rheinardkorf/dotfiles/main/.scripts/install-dotfiles.sh | bash
```

`.scripts/install-dotfiles.sh` is safe to re-run. It only does what's missing:

1. Installs the Command Line Tools if needed (for `git`; re-run once they finish).
2. Bare-clones this repo into `~/.cfg` (over https, so no SSH keys needed yet)
   and sets fetch over https, push over SSH.
3. Checks the files out into `$HOME`. Existing files that would be overwritten
   are moved to `~/.dotfiles-backup-<date>/` first.
4. Fetches the oh-my-zsh submodule.
5. Runs `.scripts/bootstrap.sh` (below).

Options: `--dry-run` (only report), `--no-bootstrap`.

Then:

- Open a new shell to get the `config` alias.
- Seed zoxide so the sesh picker knows your projects right away:
  `~/.scripts/seed-zoxide.sh --dry-run`, then without `--dry-run`
  (scans `~/Development` for git repos and worktrees; `--add <dir>` for extras).
- Name the machine (used by SketchyBar and Hammerspoon; the MDM may control
  the computer name): `echo <name> > ~/.config/machine-name`
- Grant AeroSpace and Hammerspoon Accessibility access when macOS asks.
- Set up SSH keys for GitHub before pushing.

## Bring a machine up to date

```bash
config pull --ff-only          # latest dotfiles
~/.scripts/bootstrap.sh        # install anything new (add --dry-run to just check)
```

`bootstrap.sh` is safe to re-run. It installs only what's missing and never
upgrades:

- Homebrew, the packages in `~/Brewfile.core` (everything needed on day one),
  then this machine's extras from `~/Brewfile.<machine-name>` (e.g. `Brewfile.mando`).
  Third-party tap entries marked `trusted: true` are trusted first (Homebrew 6
  requires it); `link:` options are applied.
- tmux plugins (TPM) and the catppuccin theme
- the Claude Code hooks that show 🔔 / ✓ in the tmux bar (merged into
  `~/.claude/settings.json`; other settings are kept)
- the SketchyBar and Espanso services, and a first launch of AeroSpace and
  Hammerspoon

## Everyday use

```bash
config status
config add .config/ghostty/config
config commit -m "Ghostty: bigger font"
config push
```

## Shell history and kept commands

History lasts as long as the tmux session: its panes share it, and it's deleted
when the session closes. Outside tmux it's gone when the shell exits. Nothing
goes to `~/.zsh_history`. Commands worth remembering are kept on purpose:

```bash
keep "convert video to gif"   # save the last command to ~/.config/zsh/commands.txt
keep -l "staging db"          # or to ~/.commands.local (machine-specific, not in this repo)
# Ctrl-G                      # pick a kept command onto the prompt
```

`commands.txt` is public: hosts, tokens and client names go in `~/.commands.local`.

## Adding a new app's config

`~/.gitignore` is an allowlist: it ignores everything, then lets specific paths
through. A new folder must be added there, or its new files are silently
ignored:

```gitignore
!.config/newapp/
!.config/newapp/**
```

Add the path to `.scripts/validate_config_ignore.sh` too, then check:

```bash
~/.scripts/validate_config_ignore.sh
```

## Machine-specific settings (not in this repo)

- `~/.zshrc.local`: shell settings for this machine only (loaded by `.zshrc`)
- `~/.aliases`: aliases for projects on this machine only (also loaded by `.zshrc`)
- `~/.commands.local`: kept commands for this machine only (`keep -l`, picked with Ctrl-G)
- `~/.config/machine-name`: this machine's name
- `~/.aws/config`: AWS profiles; `aws-mfa-login <profile>` reads the MFA device from there

## Careful

The work tree is `$HOME`. **Never `config checkout` a different branch or
commit**: it rewrites live files in your home folder, and files that only exist
on the current branch disappear. To update, use `config pull --ff-only`.

## Manual install (if the script can't be used)

```bash
xcode-select --install                         # if git isn't available yet
git clone --bare https://github.com/rheinardkorf/dotfiles.git ~/.cfg
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
config config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
config remote set-url --push origin git@github.com:rheinardkorf/dotfiles.git

# Move aside files the checkout would overwrite, keeping their paths
backup=~/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)
config ls-tree -r --name-only main | while read -r f; do
  if [ -e ~/"$f" ] || [ -L ~/"$f" ]; then mkdir -p "$backup/$(dirname "$f")" && mv ~/"$f" "$backup/$f"; fi
done

config checkout main
(cd ~ && config submodule update --init --recursive)   # oh-my-zsh
~/.scripts/bootstrap.sh
```

Don't create a `~/.gitignore` before checking out (the repo has one), and don't
set `status.showUntrackedFiles no` (it hides new files in allowed folders).

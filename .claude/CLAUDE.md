# Dotfiles

My dotfiles are a bare git repo in `~/.cfg` with `$HOME` as the work tree.

- Always use the `config` alias for dotfiles git commands (`config status`,
  `config add`, `config commit`, ...). Never `/usr/bin/git --git-dir=...` or
  `GIT_DIR=... GIT_WORK_TREE=...`.
- Never `config checkout` / `config switch` to a different commit: it rewrites
  live files in my home folder. Restoring single files is fine.
- Commit on a branch, then fast-forward main (`config branch -f main <branch>`,
  checking `config merge-base --is-ancestor` first).
- Only push when I explicitly say push for that change.
- `~/.gitignore` is an allowlist: new config folders must be added there (and to
  `~/.scripts/validate_config_ignore.sh`), or their files are silently ignored.

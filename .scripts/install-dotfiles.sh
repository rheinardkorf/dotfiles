#!/usr/bin/env bash
# Install the dotfiles into $HOME on a new machine, then run bootstrap.sh.
# Safe to re-run: an existing install is left as is (never re-checked-out).
#
#   curl -fsSL https://raw.githubusercontent.com/rheinardkorf/dotfiles/main/.scripts/install-dotfiles.sh | bash
#   ~/.scripts/install-dotfiles.sh [--dry-run] [--no-bootstrap]
#
# The repo is a bare clone in ~/.cfg whose work tree is $HOME. After this, open
# a new shell to get the `config` alias (git for the dotfiles).
set -uo pipefail

REPO="${DOTFILES_REPO:-https://github.com/rheinardkorf/dotfiles.git}"    # https: works before SSH keys exist
PUSH_URL="${DOTFILES_PUSH_URL:-git@github.com:rheinardkorf/dotfiles.git}"
BRANCH="${DOTFILES_BRANCH:-main}"
GIT_DIR="${DOTFILES_DIR:-$HOME/.cfg}"
WORK_TREE="${DOTFILES_HOME:-$HOME}"

DRY_RUN=false; BOOTSTRAP=true
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-bootstrap) BOOTSTRAP=false ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '  %-8s %s\n' "$1" "$2"; }
run()  { $DRY_RUN || "$@"; }
doing(){ say "$($DRY_RUN && echo would || echo doing)" "$1"; }
die()  { say "PROBLEM" "$1"; exit 1; }
cfg()  { /usr/bin/git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" "$@"; }

echo "Dotfiles$($DRY_RUN && echo ' (dry run: nothing will change)')"

# --- Command Line Tools (provides /usr/bin/git) --------------------------------
if xcode-select -p >/dev/null 2>&1; then
  say "ok" "Command Line Tools"
else
  doing "install Command Line Tools (a macOS dialog will open)"
  run xcode-select --install
  $DRY_RUN || { echo "  Re-run this script when the Command Line Tools install finishes."; exit 0; }
fi

# --- Bare clone ----------------------------------------------------------------
if [[ -d "$GIT_DIR" ]]; then
  [[ "$(/usr/bin/git --git-dir="$GIT_DIR" config --get core.bare 2>/dev/null)" == true ]] \
    || die "$GIT_DIR exists but isn't a bare git repo; move it aside and re-run"
  say "ok" "bare repo in $GIT_DIR"
else
  doing "clone $REPO into $GIT_DIR"
  run /usr/bin/git clone -q --bare "$REPO" "$GIT_DIR" || die "clone failed"
fi

# git clone --bare leaves out the fetch refspec, so origin/main never appears
if $DRY_RUN && [[ ! -d "$GIT_DIR" ]]; then
  say "would" "configure fetch refspec and push URL"
else
  if [[ -z "$(cfg config --get remote.origin.fetch)" ]]; then
    doing "configure fetch refspec"
    run cfg config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  else say "ok" "fetch refspec"; fi
  # Fetch over https, push over SSH (once SSH keys are set up)
  if [[ "$(cfg config --get remote.origin.url)" == https://* && -z "$(cfg config --get remote.origin.pushurl)" ]]; then
    doing "set push URL to $PUSH_URL"
    run cfg remote set-url --push origin "$PUSH_URL"
  else say "ok" "push URL"; fi
  run cfg fetch -q origin || say "note" "fetch failed (offline?); continuing"
fi

# --- Check out into $HOME (first install only) -----------------------------------
# A bare clone has no index; once checked out it does. An existing install is never
# re-checked-out: the work tree is $HOME, so that would overwrite live files.
if [[ -f "$GIT_DIR/index" ]]; then
  say "ok" "already checked out (branch $(cfg branch --show-current))"
  behind="$(cfg rev-list --count HEAD..origin/"$BRANCH" 2>/dev/null || echo 0)"
  (( behind > 0 )) && say "note" "$behind new commit(s) on origin/$BRANCH; update with: config pull --ff-only"
else
  # Move files that the checkout would overwrite into a dated backup folder
  backup="$WORK_TREE/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
  conflicts=()
  while IFS= read -r path; do
    [[ -e "$WORK_TREE/$path" || -L "$WORK_TREE/$path" ]] && conflicts+=("$path")
  done < <($DRY_RUN && [[ ! -d "$GIT_DIR" ]] || cfg ls-tree -r --name-only "$BRANCH")
  if (( ${#conflicts[@]} )); then
    doing "back up ${#conflicts[@]} existing file(s) to $backup"
    for path in "${conflicts[@]}"; do
      say "" "  $path"
      if ! $DRY_RUN; then
        mkdir -p "$backup/$(dirname "$path")" && mv "$WORK_TREE/$path" "$backup/$path" || die "backup of $path failed"
      fi
    done
  fi
  doing "check out $BRANCH into $WORK_TREE"
  run cfg checkout -q "$BRANCH" || die "checkout failed"
fi

# --- Submodules (oh-my-zsh) ---------------------------------------------------------
if [[ -f "$GIT_DIR/index" || $DRY_RUN == false ]]; then
  if [[ -f "$GIT_DIR/index" ]] && (cd "$WORK_TREE" && cfg submodule status 2>/dev/null) | grep -q '^-'; then
    doing "fetch submodules (oh-my-zsh)"
    run sh -c "cd '$WORK_TREE' && /usr/bin/git --git-dir='$GIT_DIR' --work-tree='$WORK_TREE' submodule update --init --recursive -q" \
      || die "submodule update failed"
  else
    say "ok" "submodules"
  fi
else
  say "would" "fetch submodules (oh-my-zsh)"
fi

# --- Bootstrap: packages, plugins, theme, hooks, services ---------------------------
if $BOOTSTRAP; then
  echo
  if [[ -x "$WORK_TREE/.scripts/bootstrap.sh" ]]; then
    "$WORK_TREE/.scripts/bootstrap.sh" $($DRY_RUN && echo --dry-run)
  elif $DRY_RUN; then
    echo "  (bootstrap.sh will run after the checkout)"
  else
    say "PROBLEM" "$WORK_TREE/.scripts/bootstrap.sh not found in the checkout"
  fi
fi

echo
$DRY_RUN || echo "Done. Open a new shell to get the \`config\` alias (git for your dotfiles)."

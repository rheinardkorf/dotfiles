#!/usr/bin/env bash
# Bring a machine up to speed with the terminal workflow. Safe to re-run:
# every step checks first and only does what's missing.
#
#   ~/.scripts/bootstrap.sh            do it
#   ~/.scripts/bootstrap.sh --dry-run  only report what's missing
#
# Assumes the dotfiles are checked out (this script lives in them).
set -uo pipefail

DRY_RUN=false; [[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

BREWFILE="${BREWFILE:-$HOME/Brewfile.core}"
TMUX_DIR="${TMUX_DIR:-$HOME/.config/tmux}"
CATPPUCCIN_VERSION="v2.3.1"   # keep in sync with theme-catppuccin.conf
CLAUDE_SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
CLAUDE_STATUS="~/.config/tmux/scripts/claude-status.sh"

ok=0; changed=0; missing=0; problems=0
say()  { printf '  %-8s %s\n' "$1" "$2"; }
okay() { say "ok" "$1"; ok=$((ok + 1)); }
todo() { if $DRY_RUN; then say "missing" "$1"; missing=$((missing + 1)); else say "install" "$1"; changed=$((changed + 1)); fi; }
fail() { say "PROBLEM" "$1"; problems=$((problems + 1)); }
run()  { $DRY_RUN || "$@"; }

echo "Bootstrap$($DRY_RUN && echo ' (dry run: nothing will change)')"

# --- Homebrew ----------------------------------------------------------------
echo "Homebrew"
if command -v brew >/dev/null; then
  okay "brew"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"; okay "brew (not on PATH in this shell)"
else
  todo "Homebrew (official installer; it will ask for your password)"
  if ! $DRY_RUN; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      && eval "$(/opt/homebrew/bin/brew shellenv)" || { fail "Homebrew install failed"; exit 1; }
  fi
fi

# --- Core packages (Brewfile.core): install missing, never upgrade ----------
echo "Packages ($(basename "$BREWFILE"))"
if [[ ! -f "$BREWFILE" ]]; then
  fail "$BREWFILE not found (are the dotfiles checked out?)"
elif command -v brew >/dev/null; then
  while read -r kind name; do
    if [[ "$kind" == cask ]]; then
      if brew list --cask "$name" >/dev/null 2>&1; then okay "$name"
      else todo "$name (cask)"; run brew install --cask "$name" </dev/null || fail "$name install failed"; fi
    else
      if brew list --formula "$name" >/dev/null 2>&1; then okay "$name"
      else todo "$name"; run brew install "$name" </dev/null || fail "$name install failed"; fi
    fi
  # </dev/null on each install: brew reads stdin and would swallow the rest of this list
  done < <(sed -nE 's/^[[:space:]]*(brew|cask)[[:space:]]+"([^"]+)".*/\1 \2/p' "$BREWFILE")
fi

# --- Desktop services: start what's installed but not running ---------------
echo "Desktop services"
if command -v brew >/dev/null && brew list --formula sketchybar >/dev/null 2>&1; then
  if brew services list 2>/dev/null | awk '$1=="sketchybar"{print $2}' | grep -qx started; then okay "sketchybar service"
  else todo "start sketchybar service (and at login)"; run brew services start sketchybar >/dev/null || fail "sketchybar service failed to start"; fi
fi
if command -v espanso >/dev/null; then
  if pgrep -xq espanso || espanso status 2>/dev/null | grep -q "is running"; then okay "espanso service"
  else todo "start espanso service (and at login)"; run sh -c 'espanso service register >/dev/null 2>&1; espanso start' || fail "espanso failed to start"; fi
fi
for app in AeroSpace Hammerspoon; do
  [[ -d "/Applications/$app.app" ]] || continue
  if pgrep -xq "$app"; then okay "$app running"
  else
    todo "launch $app (grant it Accessibility access when macOS asks)"; run open -a "$app" || fail "$app failed to launch"
  fi
done

# --- tmux plugins (TPM) ------------------------------------------------------
echo "tmux plugins"
if [[ -d "$TMUX_DIR/plugins/tpm/.git" ]]; then
  okay "tpm"
else
  todo "tpm"; run git clone -q https://github.com/tmux-plugins/tpm "$TMUX_DIR/plugins/tpm" || fail "tpm clone failed"
fi
# Plugins declared in tmux.conf (@plugin 'owner/name'), each installed by TPM
need_plugins=false
while read -r plugin; do
  [[ "$plugin" == tmux-plugins/tpm ]] && continue
  if [[ -d "$TMUX_DIR/plugins/${plugin##*/}" ]]; then okay "$plugin"
  else todo "$plugin"; need_plugins=true; fi
done < <(sed -nE "s/^[[:space:]]*set -g @plugin '([^']+)'.*/\1/p" "$TMUX_DIR/tmux.conf" 2>/dev/null)
if $need_plugins && ! $DRY_RUN; then
  # TPM's installer asks a tmux server where plugins go; use a private, temporary
  # server so it reads this machine's config and never touches a running tmux
  # TPM's installer asks a running tmux server for TMUX_PLUGIN_MANAGER_PATH. Start a
  # private, temporary server (no user config: no restore, no theme) that knows the
  # path; TPM reads the @plugin list from tmux.conf itself.
  # Unset TMUX too: inside tmux it overrides TMUX_TMPDIR and would reach the live server.
  tpm_tmp="$(mktemp -d /tmp/tpm.XXXXXX)"   # short path: tmux socket paths have a length limit
  sock="$tpm_tmp/tmux-$(id -u)/default"
  env -u TMUX TMUX_TMPDIR="$tpm_tmp" tmux -f /dev/null new-session -d -s tpm \; \
    set-environment -g TMUX_PLUGIN_MANAGER_PATH "$TMUX_DIR/plugins/" \
    && out="$(env -u TMUX TMUX_TMPDIR="$tpm_tmp" "$TMUX_DIR/plugins/tpm/bin/install_plugins" 2>&1)" \
    || fail "tpm plugin install failed: ${out:-could not start a temporary tmux server}"
  # Stop only the private server, addressed by its socket file
  [[ -S "$sock" ]] && env -u TMUX tmux -S "$sock" kill-server 2>/dev/null
  rm -rf "$tpm_tmp"
fi

# --- catppuccin theme ----------------------------------------------------------
echo "tmux theme"
CAT="$TMUX_DIR/themes/catppuccin"
if [[ -d "$CAT/.git" ]]; then
  # A commit can carry several tags (catppuccin also tags releases "latest")
  if git -C "$CAT" tag --points-at HEAD | grep -qxF "$CATPPUCCIN_VERSION"; then okay "catppuccin $CATPPUCCIN_VERSION"
  else fail "catppuccin is at $(git -C "$CAT" describe --tags 2>/dev/null || git -C "$CAT" rev-parse --short HEAD), expected $CATPPUCCIN_VERSION (left as is)"; fi
else
  todo "catppuccin $CATPPUCCIN_VERSION"
  run git clone -q -b "$CATPPUCCIN_VERSION" --depth 1 https://github.com/catppuccin/tmux.git "$CAT" 2>/dev/null \
    || fail "catppuccin clone failed"
fi

# --- Claude Code status hooks (🔔 / ✓ in the tmux bar) -------------------------
echo "Claude Code hooks"
if ! command -v claude >/dev/null && [[ ! -d "$(dirname "$CLAUDE_SETTINGS")" ]]; then
  say "skip" "Claude Code not installed"
elif ! command -v jq >/dev/null; then
  $DRY_RUN && todo "hooks (jq is installed in the Packages step)" || fail "jq needed to merge hooks"
else
  hooks=( "Notification waiting" "Stop done" "UserPromptSubmit clear" "PostToolUse resume" "SessionEnd clear" )
  [[ -f "$CLAUDE_SETTINGS" ]] || { $DRY_RUN || { mkdir -p "$(dirname "$CLAUDE_SETTINGS")"; echo '{}' > "$CLAUDE_SETTINGS"; }; }
  add=()
  for h in "${hooks[@]}"; do
    event="${h%% *}" cmd="$CLAUDE_STATUS ${h#* }"
    if [[ -f "$CLAUDE_SETTINGS" ]] && jq -e --arg e "$event" --arg c "$cmd" \
         '[.hooks[$e][]?.hooks[]?.command] | index($c)' "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
      okay "$event hook"
    else
      todo "$event hook"; add+=("$h")
    fi
  done
  if (( ${#add[@]} )) && ! $DRY_RUN; then
    cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak-bootstrap"
    tmp="$(mktemp)"; cp "$CLAUDE_SETTINGS" "$tmp"
    for h in "${add[@]}"; do
      jq --arg e "${h%% *}" --arg c "$CLAUDE_STATUS ${h#* }" \
        '.hooks[$e] = ((.hooks[$e] // []) + [{"hooks": [{"type": "command", "command": $c}]}])' \
        "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    done
    if jq -e . "$tmp" >/dev/null; then mv "$tmp" "$CLAUDE_SETTINGS"; say "" "(previous settings saved as $(basename "$CLAUDE_SETTINGS").bak-bootstrap)"
    else fail "hook merge produced invalid JSON; settings left unchanged"; rm -f "$tmp"; fi
  fi
fi

# --- Machine name (used by SketchyBar / Hammerspoon) ---------------------------
echo "Machine"
if [[ -s "$HOME/.config/machine-name" ]]; then okay "machine-name: $(head -n1 "$HOME/.config/machine-name")"
else say "note" "no ~/.config/machine-name; create it with: echo <name> > ~/.config/machine-name"; fi

# --- Summary -------------------------------------------------------------------
echo
if $DRY_RUN; then
  echo "Dry run: $ok ok, $missing missing, $problems problem(s)."
  (( missing )) && echo "Run without --dry-run to install what's missing."
else
  echo "Done: $ok already ok, $changed installed, $problems problem(s)."
  (( changed )) && [[ -n "${TMUX:-}" ]] && echo "Inside tmux: press prefix r to reload the config."
fi
(( problems == 0 ))

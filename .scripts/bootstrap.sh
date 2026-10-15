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
PANEL_EVENT='$HOME/.scripts/panel event agents'

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

# --- Packages: Brewfile.core, then Brewfile.<machine-name>; install missing, never upgrade
# Entry options understood (as written by `brew bundle dump`):
#   trusted: true   third-party tap entry to trust (Homebrew 6 only loads trusted taps)
#   link: false     don't link into the PATH;  link: true   force-link (keg-only)
install_brewfile() {
  local file="$1" kind name opts flag
  echo "Packages ($(basename "$file"))"
  while IFS=$'\t' read -r kind name opts; do
    flag=""; [[ "$kind" == cask ]] && flag="--cask"
    if brew list ${flag:---formula} "$name" >/dev/null 2>&1; then okay "$name"; continue; fi
    todo "$name${flag:+ (cask)}"
    $DRY_RUN && continue
    # </dev/null on each brew call: brew reads stdin and would swallow the rest of this list
    if [[ "$opts" == *"trusted: true"* && "$name" == */*/* ]]; then
      brew trust ${flag:---formula} "$name" </dev/null >/dev/null 2>&1 || fail "could not trust $name"
    fi
    if brew install $flag "$name" </dev/null; then
      [[ "$opts" == *"link: false"* ]] && brew unlink "$name" </dev/null >/dev/null 2>&1
      [[ "$opts" == *"link: true"* ]] && brew link --force "$name" </dev/null >/dev/null 2>&1
    else
      fail "$name install failed"
    fi
  done < <(sed -nE 's/^[[:space:]]*(brew|cask)[[:space:]]+"([^"]+)"(.*)$/\1\t\2\t\3/p' "$file")
}

MACHINE_NAME="$(head -n1 "$HOME/.config/machine-name" 2>/dev/null | tr -d '[:space:]')"
if [[ ! -f "$BREWFILE" ]]; then
  echo "Packages"; fail "$BREWFILE not found (are the dotfiles checked out?)"
elif command -v brew >/dev/null; then
  install_brewfile "$BREWFILE"
  MACHINE_BREWFILE="$(dirname "$BREWFILE")/Brewfile.$MACHINE_NAME"
  if [[ -n "$MACHINE_NAME" && -f "$MACHINE_BREWFILE" ]]; then
    install_brewfile "$MACHINE_BREWFILE"
  elif [[ -n "$MACHINE_NAME" ]]; then
    echo "Packages (machine)"; say "note" "no $(basename "$MACHINE_BREWFILE") for this machine; core only"
  fi
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

# --- Claude Code hooks: status (🔔 / ✓ in the tmux bar) and panel's agents pane --
echo "Claude Code hooks"
if ! command -v claude >/dev/null && [[ ! -d "$(dirname "$CLAUDE_SETTINGS")" ]]; then
  say "skip" "Claude Code not installed"
elif ! command -v jq >/dev/null; then
  $DRY_RUN && todo "hooks (jq is installed in the Packages step)" || fail "jq needed to merge hooks"
else
  # "<event>|<command>|<async>": async hooks run in the background (Claude doesn't wait)
  hooks=( "Notification|$CLAUDE_STATUS waiting|false" "Stop|$CLAUDE_STATUS done|false"
          "UserPromptSubmit|$CLAUDE_STATUS clear|false" "PostToolUse|$CLAUDE_STATUS resume|false"
          "PostToolUseFailure|$CLAUDE_STATUS resume|false" "SessionEnd|$CLAUDE_STATUS clear|false" )
  for event in UserPromptSubmit Stop Notification PostToolUse PostToolUseFailure SubagentStart SubagentStop SessionStart SessionEnd; do
    hooks+=( "$event|$PANEL_EVENT|true" )
  done
  [[ -f "$CLAUDE_SETTINGS" ]] || { $DRY_RUN || { mkdir -p "$(dirname "$CLAUDE_SETTINGS")"; echo '{}' > "$CLAUDE_SETTINGS"; }; }
  add=()
  for h in "${hooks[@]}"; do
    IFS='|' read -r event cmd async <<<"$h"
    label="$event hook ($(basename "${cmd%% *}"))"
    if [[ -f "$CLAUDE_SETTINGS" ]] && jq -e --arg e "$event" --arg c "$cmd" \
         '[.hooks[$e][]?.hooks[]?.command] | index($c)' "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
      okay "$label"
    else
      todo "$label"; add+=("$h")
    fi
  done
  if (( ${#add[@]} )) && ! $DRY_RUN; then
    cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak-bootstrap"
    tmp="$(mktemp)"; cp "$CLAUDE_SETTINGS" "$tmp"
    for h in "${add[@]}"; do
      IFS='|' read -r event cmd async <<<"$h"
      jq --arg e "$event" --arg c "$cmd" --argjson a "$async" \
        '.hooks[$e] = ((.hooks[$e] // []) + [{"hooks": [{"type": "command", "command": $c} + (if $a then {"async": true} else {} end)]}])' \
        "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    done
    if jq -e . "$tmp" >/dev/null; then mv "$tmp" "$CLAUDE_SETTINGS"; say "" "(previous settings saved as $(basename "$CLAUDE_SETTINGS").bak-bootstrap)"
    else fail "hook merge produced invalid JSON; settings left unchanged"; rm -f "$tmp"; fi
  fi
fi

# --- Assistant voice: Kokoro, an offline voice model for panel's HUD -------------
# Model files from the kokoro-onnx release (checked by size), and the uv
# environment the HUD runs it in, made once so the first briefing isn't slow.
echo "Assistant voice (Kokoro)"
KOKORO_DIR="${KOKORO_DIR:-$HOME/.local/share/kokoro}"
KOKORO_URL="https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0"
for f in "kokoro-v1.0.onnx 325532387" "voices-v1.0.bin 28214398"; do
  name="${f% *}" size="${f#* }"
  if [[ "$(stat -f %z "$KOKORO_DIR/$name" 2>/dev/null)" == "$size" ]]; then okay "$name"
  else
    todo "$name ($((size / 1000000)) MB)"
    if ! $DRY_RUN; then
      mkdir -p "$KOKORO_DIR"
      if curl -fsSL -o "$KOKORO_DIR/$name.part" "$KOKORO_URL/$name" &&
         [[ "$(stat -f %z "$KOKORO_DIR/$name.part")" == "$size" ]]; then
        mv "$KOKORO_DIR/$name.part" "$KOKORO_DIR/$name"
      else
        rm -f "$KOKORO_DIR/$name.part"; fail "$name download failed (or the wrong size)"
      fi
    fi
  fi
done
KOKORO_ENV=(uv run -q --no-project --python 3.12 --with kokoro-onnx --with soundfile --with sounddevice python -I -c "import kokoro_onnx, soundfile, sounddevice")
if ! command -v uv >/dev/null; then
  $DRY_RUN && todo "kokoro environment (uv is installed in the Packages step)" || fail "uv needed for the kokoro environment"
elif UV_OFFLINE=1 "${KOKORO_ENV[@]}" >/dev/null 2>&1; then   # already there: works without downloading
  okay "kokoro environment"
else
  todo "kokoro environment (Python 3.12 + kokoro-onnx, through uv)"
  run "${KOKORO_ENV[@]}" >/dev/null 2>&1 || fail "could not set up the kokoro environment"
fi

# --- Streak log: a private repo every machine shares (~/.scripts/streak) --------
echo "Streak log"
STREAK_DIR="${STREAK_DIR:-$HOME/.local/share/streak}"
STREAK_REPO="rheinardkorf/streak-log"
if [[ -d "$STREAK_DIR/.git" ]]; then
  okay "$STREAK_REPO in ${STREAK_DIR/#$HOME/~}"
elif ! gh auth status >/dev/null 2>&1; then
  $DRY_RUN && todo "$STREAK_REPO (gh needs a login first: gh auth login)" || fail "gh isn't logged in: gh auth login, then run this again"
else
  todo "$STREAK_REPO into ${STREAK_DIR/#$HOME/~}"
  run gh repo clone "$STREAK_REPO" "$STREAK_DIR" -- -q || fail "could not clone $STREAK_REPO (does this gh account have access?)"
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

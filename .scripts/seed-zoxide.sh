#!/usr/bin/env bash
# Seed zoxide with every git repo / worktree under a folder (default ~/Development),
# so the sesh picker and `z` are useful on a fresh machine.
#
#   seed-zoxide.sh                          scan ~/Development
#   seed-zoxide.sh --dry-run                only list what would be added
#   seed-zoxide.sh ~/Code ~/Work            scan these folders instead
#   seed-zoxide.sh --add ~/.config          also add a folder as-is (repeatable)
#
# A "project" is any folder containing .git (a folder for clones, a file for
# worktrees). Subfolders inside repos, archive/, node_modules and venvs are skipped.
# Safe to repeat, but each run bumps the seeded folders' scores slightly.
set -uo pipefail

DRY_RUN=false; roots=(); extras=()
while (( $# )); do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --add) [[ -n "${2:-}" ]] || { echo "--add needs a folder" >&2; exit 2; }; extras+=("$2"); shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) roots+=("$1") ;;
  esac
  shift
done
(( ${#roots[@]} )) || roots=("$HOME/Development")
command -v zoxide >/dev/null || { echo "zoxide not installed (brew install zoxide)" >&2; exit 1; }

found=()
for root in "${roots[@]}"; do
  root="${root%/}"
  if [[ ! -d "$root" ]]; then echo "skip: $root (not a folder)" >&2; continue; fi
  if [[ -e "$root/.git" ]]; then found+=("$root"); continue; fi   # the root is itself a repo
  while IFS= read -r dir; do found+=("$dir"); done < <(
    find "$root" -maxdepth 5 \
        \( -name node_modules -o -name .venv -o -name venv -o -name .bare -o -name archive \) -prune \
        -o -name .git -print 2>/dev/null | sed 's#/\.git$##' | sort -u
  )
done

for dir in ${extras[@]+"${extras[@]}"}; do
  if [[ -d "$dir" ]]; then found+=("${dir%/}"); else echo "skip: $dir (not a folder)" >&2; fi
done

before=$(zoxide query --list 2>/dev/null | wc -l | tr -d ' ')
for dir in ${found[@]+"${found[@]}"}; do
  if $DRY_RUN; then echo "would add: ${dir/#$HOME/~}"; else zoxide add "$dir"; fi
done

if $DRY_RUN; then
  echo "${#found[@]} folder(s) would be added (zoxide currently knows $before)."
else
  echo "Added ${#found[@]} folder(s). zoxide now knows $(zoxide query --list | wc -l | tr -d ' ') (was $before)."
fi

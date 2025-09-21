# ==============================================================================
# Git Worktree Helper (gwt) - Zsh Functions (with Auto-CD)
# ==============================================================================

# --- Internal Helper Functions ---

_gwt_help() {
  cat <<-'EOF'
Git Worktree Helper (gwt)

Manage Git worktrees with ease.

Usage: gwt <subcommand> [options]

Subcommands:
  list | ls | l                    List worktrees with details.
  add | a <branch> [remote] [path]   Add worktree from remote branch and cd into it.
                                   (Default remote: origin, path: ../<branch>)
  add-local | al <branch> [path]     Add worktree from local branch and cd into it.
                                   (Default path: ../<branch>)
  remove | rm <path> [--force]       Remove a worktree by path.
  remove-interactive | rmi           Interactively select & remove a worktree.
  prune | p                          Prune worktree metadata.
  move | mv <old-path> <new-path>    Move a worktree.
  lock <path>                        Lock a worktree (prevents removal/pruning).
  unlock <path>                      Unlock a worktree.
  cd                                 Interactively cd into a worktree (requires fzf).
  help | -h | --help                 Show this help message.

EOF
}

_gwt_list() {
  git worktree list -v
}

_gwt_add_remote() {
  local branch_name="$1"
  local remote_name="${2:-origin}"
  local path_prefix="${3:-../}"
  local worktree_path

  if [[ -z "$branch_name" ]]; then
    echo "Error: Missing branch name."
    echo "Usage: gwt add <branch-name> [remote-name] [path-prefix]"
    return 1
  fi

  if [[ -n "$path_prefix" && "$path_prefix" != "./" && "$path_prefix" != "../" && "$path_prefix" != */ ]]; then
      path_prefix="${path_prefix}/"
  fi
  worktree_path="$path_prefix$branch_name"

  echo "Fetching $remote_name..."
  if ! git fetch "$remote_name"; then
    echo "Error: Failed to fetch from $remote_name."
    return 1
  fi

  echo "Creating worktree for $remote_name/$branch_name at $worktree_path..."
  if ! git worktree add --track -b "$branch_name" "$worktree_path" "$remote_name/$branch_name"; then
    echo "Error: Failed to create worktree."
    return 1
  fi

  # <<< CHANGE: Added cd command >>>
  echo "Worktree created. Changing directory to $worktree_path..."
  if ! cd "$worktree_path"; then
      echo "Error: Could not change directory to $worktree_path."
      return 1
  fi
  # <<< END CHANGE >>>
}

_gwt_add_local() {
  local branch_name="$1"
  local path_prefix="${2:-../}"
  local worktree_path

  if [[ -z "$branch_name" ]]; then
    echo "Error: Missing branch name."
    echo "Usage: gwt add-local <branch-name> [path-prefix]"
    return 1
  fi

  if [[ -n "$path_prefix" && "$path_prefix" != "./" && "$path_prefix" != "../" && "$path_prefix" != */ ]]; then
      path_prefix="${path_prefix}/"
  fi
  worktree_path="$path_prefix$branch_name"

  echo "Creating worktree for $branch_name at $worktree_path..."
  if ! git worktree add "$worktree_path" "$branch_name"; then
    echo "Error: Failed to create worktree."
    return 1
  fi

  # <<< CHANGE: Added cd command >>>
  echo "Worktree created. Changing directory to $worktree_path..."
  if ! cd "$worktree_path"; then
      echo "Error: Could not change directory to $worktree_path."
      return 1
  fi
  # <<< END CHANGE >>>
}

_gwt_remove() {
  if [[ -z "$1" ]]; then
    echo "Error: Missing worktree path."
    echo "Usage: gwt remove <path-to-worktree> [--force]"
    echo "  Tip: Use 'gwt remove-interactive' for an easier way."
    return 1
  fi
  git worktree remove "$@"
}

_gwt_remove_interactive() {
    local worktrees wt_path REPLY
    readarray -t worktrees < <(git worktree list | grep -v "(bare)" | grep -v "$(pwd | sed 's/\/$//')" | awk '{print $1}')

    if [ ${#worktrees[@]} -eq 0 ]; then
        echo "No other worktrees to remove."
        return 0
    fi

    echo "Select a worktree to remove:"
    select wt_path in "${worktrees[@]}"; do
        if [ -n "$wt_path" ]; then
            read -q "REPLY?Are you sure you want to remove '$wt_path'? (y/N) "
            echo
            if [[ "$REPLY" =~ ^[Yy]$ ]]; then
                echo "Removing $wt_path..."
                git worktree remove "$wt_path"
            else
                echo "Removal cancelled."
            fi
            break
        else
            echo "Invalid selection."
            break
        fi
    done
}

_gwt_prune() {
  git worktree prune
}

_gwt_move() {
  if [[ "$#" -ne 2 ]]; then
    echo "Error: Requires exactly two arguments."
    echo "Usage: gwt move <old-path> <new-path>"
    return 1
  fi
  git worktree move "$1" "$2"
}

_gwt_lock() {
  if [[ -z "$1" ]]; then
    echo "Error: Missing worktree path."
    echo "Usage: gwt lock <path-to-worktree>"
    return 1
  fi
  git worktree lock "$1"
}

_gwt_unlock() {
  if [[ -z "$1" ]]; then
    echo "Error: Missing worktree path."
    echo "Usage: gwt unlock <path-to-worktree>"
    return 1
  fi
  git worktree unlock "$1"
}

_gwt_cd() {
  if ! command -v fzf &> /dev/null; then
      echo "Error: fzf is not installed. Please install it to use 'gwt cd'."
      echo "See: https://github.com/junegunn/fzf"
      return 1
  fi

  local selected_path
  selected_path=$(git worktree list | awk '{print $1}' | fzf --prompt="Select worktree to cd into: " --height 40% --reverse)
  if [[ -n "$selected_path" ]]; then
    cd "$selected_path" || return 1
    echo "Changed directory to $selected_path"
  else
    echo "No worktree selected."
    return 1
  fi
}


# --- The Main Dispatcher Function ---
unalias gwt 2>/dev/null # Remove omz git plugin's alias

gwt() {
  local subcommand="$1"

  if [[ -z "$subcommand" ]]; then
      _gwt_help
      return 0
  fi

  shift

  case "$subcommand" in
    list|ls|l)
      _gwt_list "$@"
      ;;
    add|a)
      _gwt_add_remote "$@"
      ;;
    add-local|al)
      _gwt_add_local "$@"
      ;;
    remove|rm)
      _gwt_remove "$@"
      ;;
    remove-interactive|rmi)
      _gwt_remove_interactive "$@"
      ;;
    prune|p)
      _gwt_prune "$@"
      ;;
    move|mv)
      _gwt_move "$@"
      ;;
    lock)
      _gwt_lock "$@"
      ;;
    unlock)
      _gwt_unlock "$@"
      ;;
    cd)
      _gwt_cd "$@"
      ;;
    help|-h|--help)
      _gwt_help
      ;;
    *)
      echo "Error: Unknown gwt subcommand '$subcommand'" >&2
      _gwt_help
      return 1
      ;;
  esac

  return $?
}

# ==============================================================================

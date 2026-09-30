## NVM (lazy-loaded)
# Loading nvm.sh takes ~2s, so it only loads when actually needed:
#   - your default Node is put on PATH directly, so node/npm/global tools work instantly
#   - running `nvm` loads the real thing on first use
#   - .nvmrc switching still happens on cd, but nvm only loads in folders that have one
export NVM_DIR="$HOME/.nvm"

# Put the default Node version on PATH without loading nvm
_nvm_default_bin() {
  local alias_name version dir
  alias_name="$(<"$NVM_DIR/alias/default")" 2>/dev/null || return 1
  version="${alias_name#v}"
  # Exact match (v22.13.1), otherwise the newest installed version with that prefix (v22)
  dir="$NVM_DIR/versions/node/v$version"
  if [[ ! -d "$dir" ]]; then
    dir=( "$NVM_DIR"/versions/node/v${version}(.|*)(N/On) )   # newest first
    dir="${dir[1]}"
  fi
  [[ -d "$dir/bin" ]] && print -r -- "$dir/bin"
}
if _default_bin="$(_nvm_default_bin)"; then
  path=("$_default_bin" ${path:#$NVM_DIR/versions/node/*})
fi
unset _default_bin

# Load the real nvm (once), without re-running its own default switch
_nvm_load() {
  (( $+functions[nvm_find_nvmrc] )) && return
  unfunction nvm 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  return 0   # the completion file can exit non-zero; nvm itself loaded fine
}
nvm() { _nvm_load; nvm "$@"; }

# Switch Node to match .nvmrc on cd; revert to the default when leaving
autoload -U add-zsh-hook
load-nvmrc() {
  local dir="$PWD" nvmrc_path=""
  while :; do
    [[ -f "$dir/.nvmrc" ]] && { nvmrc_path="$dir/.nvmrc"; break; }
    [[ "$dir" == / ]] && break
    dir="${dir:h}"
  done

  if [[ -n "$nvmrc_path" ]]; then
    _nvm_load
    local node_version nvmrc_node_version
    node_version="$(nvm version)"
    nvmrc_node_version="$(nvm version "$(<"$nvmrc_path")")"
    if [[ "$nvmrc_node_version" == "N/A" ]]; then
      nvm install
    elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
      nvm use
    fi
    _nvmrc_switched=1
  elif [[ -n "$_nvmrc_switched" ]]; then
    echo "Reverting to nvm default version"
    nvm use default
    unset _nvmrc_switched
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

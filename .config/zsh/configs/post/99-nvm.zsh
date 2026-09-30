## NVM (lazy-loaded)
# Loading nvm.sh takes ~2s, so it only loads when actually needed:
#   - Node versions (the default, and .nvmrc on cd) are switched by putting the
#     installed version's bin/ on PATH directly, so node/npm/global tools work instantly
#   - running `nvm` loads the real thing on first use
#   - real nvm is only used for .nvmrc values that aren't a plain installed
#     version (lts/*, node, or a version that still needs installing)
export NVM_DIR="$HOME/.nvm"

# bin/ dir of the installed Node matching a version spec: exact (v22.13.1),
# otherwise the newest installed version with that prefix (22, v22, 22.1)
_nvm_bin_for() {
  local version="${1#v}" dir
  [[ "$version" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || return 1
  dir="$NVM_DIR/versions/node/v$version"
  if [[ ! -d "$dir" ]]; then
    dir=( "$NVM_DIR"/versions/node/v${version}.*(N/On) )   # newest first
    dir="${dir[1]}"
  fi
  [[ -d "$dir/bin" ]] && print -r -- "$dir/bin"
}
_nvm_default_bin() {
  _nvm_bin_for "$(<"$NVM_DIR/alias/default")" 2>/dev/null
}
# Put a Node bin/ first on PATH, replacing any other nvm-managed Node
_nvm_path_use() {
  path=("$1" ${path:#$NVM_DIR/versions/node/*})
}

if _default_bin="$(_nvm_default_bin)"; then
  _nvm_path_use "$_default_bin"
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
  local dir="$PWD" nvmrc_path="" spec bin
  while :; do
    [[ -f "$dir/.nvmrc" ]] && { nvmrc_path="$dir/.nvmrc"; break; }
    [[ "$dir" == / ]] && break
    dir="${dir:h}"
  done

  if [[ -n "$nvmrc_path" ]]; then
    spec="$(<"$nvmrc_path")"; spec="${spec//[[:space:]]/}"
    if bin="$(_nvm_bin_for "$spec")"; then
      # Fast path: the requested version is installed
      if [[ "${path[1]}" != "$bin" ]]; then
        _nvm_path_use "$bin"
        echo "Now using node ${${bin:h}:t} (.nvmrc: $spec)"
      fi
    else
      # lts/*, node, or not installed yet: let real nvm handle it
      _nvm_load
      local node_version nvmrc_node_version
      node_version="$(nvm version)"
      nvmrc_node_version="$(nvm version "$spec")"
      if [[ "$nvmrc_node_version" == "N/A" ]]; then
        nvm install
      elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
        nvm use
      fi
    fi
    _nvmrc_switched=1
  elif [[ -n "$_nvmrc_switched" ]]; then
    if bin="$(_nvm_default_bin)"; then
      _nvm_path_use "$bin"
      echo "Reverting to nvm default version (${${bin:h}:t})"
    else
      _nvm_load; nvm use default
    fi
    unset _nvmrc_switched
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

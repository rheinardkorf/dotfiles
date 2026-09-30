export ZSH="$HOME/.config/oh-my-zsh"
ZSH_CUSTOM=$HOME/.config/zsh/custom
ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

if [ ! -z $HOME/.config/zsh/functions ]; then
  for function in $HOME/.config/zsh/functions/*; do
    source $function
  done
fi

# extra files in ~/.zsh/configs/pre , ~/.zsh/configs , and ~/.zsh/configs/post
# these are loaded first, second, and third, respectively.
_load_settings() {
  _dir="$1"

  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/**/*(N-.); do
        if [ ${config:e} = "zwc" ] ; then continue ; fi
        . $config
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/pre/*)
          :
          ;;
        "$_dir"/post/*)
          :
          ;;
        *)
          if [[ -f $config && ${config:e} != "zwc" ]]; then
            . $config
          fi
          ;;
      esac
    done

    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/**/*(N-.); do
        if [ ${config:e} = "zwc" ] ; then continue ; fi
        . $config
      done
    fi
  fi
}
_load_settings "$HOME/.config/zsh/configs"

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases


# nvm: loaded lazily in ~/.config/zsh/configs/post/99-nvm.zsh (loading it here too
# doubled shell startup time)

# Tools installed by uv / Claude Code's installers live in ~/.local/bin (if present)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

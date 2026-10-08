## fzf-tab: Tab completion as an fzf list (brew "fzf-tab").
# Loaded after oh-my-zsh's compinit and before 10-fzf.zsh: fzf's own Tab binding
# then hands plain Tab to fzf-tab and keeps **<Tab> for itself.
_fzf_tab="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"
[[ -r $_fzf_tab ]] && source "$_fzf_tab"
unset _fzf_tab

# Previews: folder contents for cd, and Tab switches between completion groups
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'

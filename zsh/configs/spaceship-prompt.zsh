SPACESHIP_PROMPT_ORDER=(
#   time          # Time stamps section
#   user          # Username section
#   host          # Hostname section
#   hg            # Mercurial section (hg_branch  + hg_status)
#   package       # Package version
#   node          # Node.js section
#   ruby          # Ruby section
#   elixir        # Elixir section
#   xcode         # Xcode section
#   swift         # Swift section
#   golang        # Go section
#   php           # PHP section
#   rust          # Rust section
#   haskell       # Haskell Stack section
#   julia         # Julia section
#   docker        # Docker section
#   aws           # Amazon Web Services section
#   venv          # virtualenv section
#   conda         # conda virtualenv section
#   pyenv         # Pyenv section
#   dotnet        # .NET section
#   ember         # Ember.js section
#   kubecontext   # Kubectl context section
#   terraform     # Terraform workspace section
#   exec_time     # Execution time
  battery       # Battery level and status
#   vi_mode       # Vi-mode indicator
#   jobs          # Background jobs indicator
  exit_code     # Exit code section
  line_sep      # Line break
  dir           # Current directory section
  git           # Git section (git_branch + git_status)
  char          # Prompt character
)

SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=false
SPACESHIP_CHAR_SYMBOL="$ "
SPACESHIP_CHAR_COLOR_SUCCESS="250"
SPACESHIP_CHAR_COLOR_FAILURE="250"
SPACESHIP_CHAR_COLOR_SECONDARY="250"
SPACESHIP_DIR_COLOR="075"
SPACESHIP_DIR_TRUNC_PREFIX=""
SPACESHIP_GIT_PREFIX=""
SPACESHIP_GIT_SUFFIX=" "
SPACESHIP_GIT_SYMBOL=""
SPACESHIP_GIT_BRANCH_PREFIX="("
SPACESHIP_GIT_BRANCH_COLOR="126"
SPACESHIP_GIT_BRANCH_SUFFIX=")"
SPACESHIP_GIT_STATUS_PREFIX=""
SPACESHIP_GIT_STATUS_SUFFIX=""
SPACESHIP_GIT_STATUS_COLOR="136"

export LSCOLORS="exfxcxdxbxegedabagacad"
export LS_COLORS='di=38;5;111:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
export GREP_COLOR='1;33'
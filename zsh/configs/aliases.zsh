# == ALIAS ==

alias envsubst='/usr/local/opt/gettext/bin/envsubst'

# WPCS
alias wpcs='phpcs --extensions=php --ignore=*/vendor/*,*/node_modules/*,*/dev-lib/*,*/tests/* --encoding=utf-8 --basepath=. --parallel=10 --standard=WordPress-Extra -d memory_limit=-1 .'
alias wpcbf='phpcbf --extensions=php --ignore=*/vendor/*,*/node_modules/*,*/dev-lib/*,*/tests/* --encoding=utf-8 --basepath=. --parallel=10 --standard=WordPress-Extra -d memory_limit=-1 .'

# YARN
alias yw='yarn workspace'
alias yws='yarn workspaces'
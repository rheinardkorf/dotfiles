#!/usr/bin/env zsh

cat ~/.code_profiles/jsdev/ext/extensions.json | jq ".[].identifier.id" | xargs -L1 zsh -ic 'jsdev --install-extension "$0"'
# cat ~/.code_profiles/wpdev/ext/extensions.json | jq ".[].identifier.id" | xargs -L1 zsh -ic 'wpdev --install-extension "$0"'
cat ~/.code_profiles/rustdev/ext/extensions.json | jq ".[].identifier.id" | xargs -L1 zsh -ic 'rusting --install-extension "$0"'
cat ~/.code_profiles/foam/ext/extensions.json | jq ".[].identifier.id" | xargs -L1 zsh -ic 'foam --install-extension "$0"'
# cat ~/.code_profiles/fpc/ext/extensions.json | jq ".[].identifier.id" | xargs -L1 zsh -ic 'pasdev --install-extension "$0"'
cat ~/.code_profiles/pydev/ext/extensions.json | jq ".[].identifier.id" | xargs -L1 zsh -ic 'pydev --install-extension "$0"'
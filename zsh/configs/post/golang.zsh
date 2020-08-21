# == GO lang ==

# Homebrew takes care of this, but on another system you
# may need to specify these explicitly.
#
# export GOPATH="/go"
# export GOROOT="/usr/local/Cellar/go/1.10.3/libexec"
# export GOTOOLDIR="/usr/local/Cellar/go/1.10.3/libexec/pkg/tool/darwin_amd64"

export PATH="$GOPATH/bin:$PATH"

# == GO Version Manager (gvm) ===
# https://github.com/moovweb/gvm
export PATH="$HOME/.gvm/bin:$PATH"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

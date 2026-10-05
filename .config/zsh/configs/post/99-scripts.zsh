# Personal commands in ~/.scripts (e.g. wt) on PATH. Appended, so they never shadow system tools.
[[ :$PATH: == *:$HOME/.scripts:* ]] || path+=("$HOME/.scripts")

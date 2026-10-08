# keep: history by choice. Shell history is short-lived (99-history.zsh), so
# commands worth remembering are kept on purpose:
#
#   keep [note]           save the last command to ~/.config/zsh/commands.txt
#   keep -l [note]        save it to ~/.commands.local instead (not in dotfiles)
#   Ctrl-G                pick a kept command (both files) and put it on the prompt
#
# commands.txt is in the public dotfiles repo: anything with hosts, tokens or
# client names belongs in ~/.commands.local. Both files are plain text, edit freely:
#
#   # a note about the command (optional, the lines right above it)
#   the command
#
# Entries are separated by blank lines.

KEEP_FILE=~/.config/zsh/commands.txt
KEEP_LOCAL=~/.commands.local

keep() {
  local file=$KEEP_FILE
  if [[ $1 == -l || $1 == --local ]]; then
    file=$KEEP_LOCAL
    shift
  fi
  local note="$*"

  # The keep line itself is already in history; take the newest line before it
  zmodload -F zsh/parameter p:history
  local cmd= line
  local -i n
  for (( n = HISTCMD; n > 0 && n > HISTCMD - 20; n-- )); do
    line=${history[$n]-}
    [[ -z $line || $line == keep || $line == "keep "* ]] && continue
    cmd=$line
    break
  done
  if [[ -z $cmd ]]; then
    print -u2 "keep: no previous command in this shell"
    return 1
  fi

  if [[ $file == $KEEP_FILE ]] &&
     print -r -- "$cmd" | grep -qiE '(token|secret|passw|api[_-]?key|bearer|authorization)'; then
    print -u2 "keep: this looks like it has a secret; use keep -l (not in dotfiles)"
    return 1
  fi

  if [[ -f $file ]] && grep -qxF -- "$cmd" "$file"; then
    print "Already kept: $cmd"
    return 0
  fi

  {
    [[ -s $file ]] && print
    [[ -n $note ]] && print -r -- "# $note"
    print -r -- "$cmd"
  } >> "$file"
  print "Kept in ${file/#$HOME/~}: $cmd"
}

# Ctrl-G: fuzzy-pick a kept command, listed as "command : note". Searches notes
# and commands; the command lands on the prompt to edit or run.
_keep_pick() {
  local -a files=($KEEP_FILE(N) $KEEP_LOCAL(N))
  (( $#files )) || { zle -M "No kept commands yet (keep [note] saves the last one)"; return }

  # Each line is "<shown>\t<command>": fzf shows field 1, the pick keeps the rest,
  # so a " : " or tab inside the command can't be mistaken for the separator
  local picked
  picked="$(awk '
      /^[[:space:]]*$/ { note = ""; next }
      /^#/ { sub(/^#[[:space:]]*/, ""); note = (note == "" ? $0 : note " " $0); next }
      { shown = $0; gsub(/\t/, " ", shown)
        print shown (note == "" ? "" : " : " note) "\t" $0; note = "" }
    ' $files |
    fzf --height 40% --reverse --delimiter '\t' --with-nth 1 --prompt 'kept> ' |
    cut -f2-)"

  if [[ -n $picked ]]; then
    BUFFER=$picked
    CURSOR=$#BUFFER
  fi
  zle reset-prompt
}
zle -N _keep_pick
bindkey '^G' _keep_pick

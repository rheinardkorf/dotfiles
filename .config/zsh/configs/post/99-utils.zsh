## Utils
alias openports="sudo lsof -nP -iTCP -sTCP:LISTEN"
alias frequency_in_path='while read -r Line; do; grep -rnw ./ -e "$Line" | wc -l |xargs echo $Line; done;'

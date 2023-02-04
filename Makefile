DOTFILE=`pwd`

.PHONY: default
default:
	@echo $(DOTFILE)

.PHONE: zsh
zsh:
	@DOTFILE=${DOTFILE} ./bin/init-zsh

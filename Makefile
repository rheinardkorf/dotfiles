DOTFILE=`pwd`

.PHONY: default
default:
	@echo $(DOTFILE)

.PHONY: zsh
zsh:
	@DOTFILE=$(DOTFILE) ./bin/init-zsh


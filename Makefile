.PHONY: install clean

CURRENT_PATH=$(shell pwd)
DOTFILES=$(HOME)/.vimrc \
	$(HOME)/.vim \
	$(HOME)/.zshrc \
	$(HOME)/.screenrc \
	$(HOME)/.perltidyrc \
	$(HOME)/.tmux.conf \
	$(HOME)/.ocamlinit

all: dein-installer.sh

install: $(DOTFILES)

dein-installer.sh:
	curl -L https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh -o $@

$(HOME)/.zshrc:
	ln -s $(CURRENT_PATH)/zshrc $@

$(HOME)/.vimrc:
	ln -s $(CURRENT_PATH)/vimrc $@

$(HOME)/.vim: dein-installer.sh
	-mkdir -p $@/dein
	sh dein-installer.sh $@/dein

$(HOME)/.screenrc:
	ln -s $(CURRENT_PATH)/screenrc $@

$(HOME)/.perltidyrc:
	ln -s $(CURRENT_PATH)/perltidyrc $@

$(HOME)/.tmux.conf:
	ln -s $(CURRENT_PATH)/tmux.conf $@

$(HOME)/.ocamlinit:
	ln -s $(CURRENT_PATH)/ocamlinit $@

clean:
	-rm -rf $(DOTFILES)

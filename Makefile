.PHONY: install clean

CURRENT_PATH=$(shell pwd)
DOTFILES=$(HOME)/.vimrc \
	$(HOME)/.vim \
	$(HOME)/.zshrc \
	$(HOME)/.screenrc \
	$(HOME)/.perltidyrc \
	$(HOME)/.tmux.conf \
	$(HOME)/.gitconfig \
	$(HOME)/.gitignore_global \
	$(HOME)/.ocamlinit

all: dein-installer.sh

install: $(DOTFILES)

dein-installer.sh:
	curl -L https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh -o $@
	if ! [ $$(which realpath) ]; then sed -i -e 's/realpath/readlink -e/' $@; fi

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

$(HOME)/.gitconfig:
	ln -s $(CURRENT_PATH)/gitconfig $@

$(HOME)/.gitignore_global:
	ln -s $(CURRENT_PATH)/gitignore_global $@

clean:
	-rm -rf $(DOTFILES) dein-installer.sh

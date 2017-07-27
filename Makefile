.PHONY: install clean

DOTFILES=$(HOME)/.vimrc \
	$(HOME)/.vim \
	$(HOME)/.zshrc \
	$(HOME)/.screenrc \
	$(HOME)/.perltidyrc \
	$(HOME)/.tmux.conf \
	$(HOME)/.gitconfig \
	$(HOME)/.gitignore_global \
	$(HOME)/.ocamlinit

all: dein-installer.sh tmux-colors-solarized
	cd tmux-colors-solarized && git pull

install: $(DOTFILES)

dein-installer.sh:
	curl -L https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh -o $@
	if ! [ $$(which realpath) ]; then sed -i -e 's/realpath/readlink -e/' $@; fi

tmux-colors-solarized:
	git clone git@github.com:seebi/$@.git

$(HOME)/.zshrc:
	ln -s zshrc $@

$(HOME)/.vimrc:
	ln -s vimrc $@

$(HOME)/.vim: dein-installer.sh
	-mkdir -p $@/dein
	sh dein-installer.sh $@/dein

$(HOME)/.screenrc:
	ln -s screenrc $@

$(HOME)/.perltidyrc:
	ln -s perltidyrc $@

$(HOME)/.tmux.conf:
	cat ./tmux.conf ./tmux-colors-solarized/tmuxcolors-dark.conf > $@

$(HOME)/.ocamlinit:
	ln -s ocamlinit $@

$(HOME)/.gitconfig:
	ln -s gitconfig $@

$(HOME)/.gitignore_global:
	ln -s gitignore_global $@

clean:
	-rm -rf $(DOTFILES) dein-installer.sh

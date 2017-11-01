.PHONY: all install clean realclean

SRC = zshrc vimrc screenrc tmux.conf perltidyrc ocamlinit gitconfig gitignore_global fzf fzf.zsh vim
TARGET = $(addprefix $(HOME)/.,$(SRC))

all: dein-installer.sh fzf
	git -C fzf pull

dein-installer.sh:
	curl -L https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh -o $@
	if ! [ $$(which realpath) ]; then sed -i -e 's/realpath/readlink -e/' $@; fi

fzf:
	git clone git@github.com:junegunn/$@.git

install: $(TARGET)

$(HOME)/.%:
	ln -s `pwd`/$* $@

$(HOME)/.fzf.zsh: $(HOME)/.fzf
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

$(HOME)/.vim: dein-installer.sh
	-mkdir -p $@/dein
	sh $< $@/dein

clean:
	rm -rf $(TARGET)

realclean: clean
	rm -rf dein-installer.sh fzf

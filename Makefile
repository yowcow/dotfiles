.PHONY: all install clean realclean

SRC = zshrc vimrc screenrc tmux.conf perltidyrc ocamlinit gitconfig gitignore_global fzf fzf.zsh vim
TARGET = $(addprefix $(HOME)/.,$(SRC))

all: dein-installer.sh fzf tmux-colors-solarized
	git -C fzf pull
	git -C tmux-colors-solarized pull

dein-installer.sh:
	curl -L https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh -o $@
	if ! [ $$(which realpath) ]; then sed -i -e 's/realpath/readlink -e/' $@; fi

tmux-colors-solarized:
	git clone git@github.com:seebi/$@.git

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

$(HOME)/.tmux.conf: tmux-colors-solarized
	cat tmux.conf $</tmuxcolors-dark.conf > $@

clean:
	rm -rf $(TARGET)

realclean: clean
	rm -rf dein-installer.sh fzf tmux-colors-solarized

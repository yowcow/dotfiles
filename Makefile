.PHONY: all install clean realclean

SRC = \
	zshrc \
	vimrc \
	screenrc \
	tmux.conf \
	perltidyrc \
	ocamlinit \
	gitconfig \
	gitignore_global \
	fzf \
	fzf.zsh \
	vim \
	vim/autoload/plug.vim \
	config/nvim/init.vim \
	local/share/nvim/site/autoload/plug.vim

TARGET = $(addprefix $(HOME)/.,$(SRC))

all: vim-plug fzf tmux-colors-solarized
	git -C vim-plug pull
	git -C fzf pull
	git -C tmux-colors-solarized pull

tmux-colors-solarized:
	git clone git@github.com:seebi/$@.git

fzf:
	git clone git@github.com:junegunn/$@.git

vim-plug:
	git clone git@github.com:junegunn/$@.git

install: $(TARGET)

$(HOME)/.%:
	ln -s `pwd`/$* $@

$(HOME)/.fzf.zsh: $(HOME)/.fzf
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

$(HOME)/.vim:
	-mkdir -p $@

$(HOME)/.vim/autoload/plug.vim: vim-plug
	mkdir -p $(dir $@)
	ln -s `pwd`/$</plug.vim $@

$(HOME)/.tmux.conf: tmux-colors-solarized tmux.conf
	cat tmux.conf $</tmuxcolors-dark.conf > $@

$(HOME)/.config/nvim/init.vim: vimrc
	mkdir -p $(dir $@)
	ln -s `pwd`/$< $@

$(HOME)/.local/share/nvim/site/autoload/plug.vim: vim-plug
	mkdir -p $(dir $@)
	ln -s `pwd`/$</plug.vim $@

clean:
	rm -rf $(TARGET)

realclean: clean
	rm -rf vim-plug fzf tmux-colors-solarized

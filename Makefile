.PHONY: all pull-src/% install clean realclean

SRC = \
	zshrc \
	vimrc \
	screenrc \
	tmux.conf \
	perltidyrc \
	ocamlinit \
	gitconfig \
	gitignore_global

NOSRC = \
	$(HOME)/.fzf \
	$(HOME)/.fzf.zsh \
	$(HOME)/.vim/autoload/plug.vim \
	$(HOME)/.config/nvim/init.vim \
	$(HOME)/.local/share/nvim/site/autoload/plug.vim \
	$(HOME)/.goenv

TARGET = $(addprefix $(HOME)/.,$(SRC)) $(NOSRC)

VIM_PLUG = src/github.com/junegunn/vim-plug
FZF = src/github.com/junegunn/fzf
TMUX_COLORS_SOLARIZED = src/github.com/seebi/tmux-colors-solarized
GOENV = src/github.com/syndbg/goenv

GITMODULES = $(VIM_PLUG) $(FZF) $(TMUX_COLORS_SOLARIZED) $(GOENV)

all:
	$(MAKE) -j4 $(GITMODULES)
	$(MAKE) -j4 $(foreach mod,$(GITMODULES),pull-$(mod))

src/%:
	mkdir -p $(dir $@)
	echo $* | sed -e 's|/|:|' | xargs -I{} git clone git@{} $@

pull-src/%:
	cd src/$* && git pull

install: $(TARGET) $(HOME)/go/bin/dep

$(HOME)/.%:
	ln -s `pwd`/$* $@

$(HOME)/.fzf: $(FZF)
	ln -s `pwd`/$< $@

$(HOME)/.fzf.zsh: $(HOME)/.fzf
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

$(HOME)/.vim/autoload/plug.vim: $(VIM_PLUG)
	mkdir -p $(dir $@)
	ln -s `pwd`/$</plug.vim $@

$(HOME)/.tmux.conf: $(TMUX_COLORS_SOLARIZED) tmux.conf
	cat tmux.conf $</tmuxcolors-dark.conf > $@

$(HOME)/.config/nvim/init.vim: vimrc
	mkdir -p $(dir $@)
	ln -s `pwd`/$< $@

$(HOME)/.local/share/nvim/site/autoload/plug.vim: $(VIM_PLUG)
	mkdir -p $(dir $@)
	ln -s `pwd`/$</plug.vim $@

$(HOME)/.goenv: $(GOENV)
	ln -s `pwd`/$< $@

$(HOME)/go/bin/dep: $(HOME)/go/bin
	curl https://raw.githubusercontent.com/golang/dep/master/install.sh | INSTALL_DIRECTORY=$(dir $@) sh

$(HOME)/go/bin:
	mkdir -p $@

clean:
	rm -rf $(TARGET) $(HOME)/go/bin/dep

realclean: clean
	rm -rf src

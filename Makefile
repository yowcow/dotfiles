.PHONY: all pull-src/% install clean realclean

SRC := \
	zshrc \
	vimrc \
	screenrc \
	tmux.conf \
	perltidyrc \
	ocamlinit \
	gitconfig \
	gitignore_global \
	ctags

NOSRC := \
	$(HOME)/.fzf \
	$(HOME)/.fzf.zsh \
	$(HOME)/.vim/autoload/plug.vim \
	$(HOME)/.config/nvim/init.vim \
	$(HOME)/.config/nvim/colors/molokai.vim \
	$(HOME)/.local/share/nvim/site/autoload/plug.vim \
	$(HOME)/.goenv

TARGET = $(addprefix $(HOME)/.,$(SRC)) $(NOSRC)

VIM_PLUG := src/github.com/junegunn/vim-plug
FZF := src/github.com/junegunn/fzf
MOLOKAI := src/github.com/tomasr/molokai
GOENV := src/github.com/syndbg/goenv

GITMODULES := $(VIM_PLUG) $(FZF) $(GOENV)

all:
	$(MAKE) -j4 $(GITMODULES)
	$(MAKE) -j4 $(foreach mod,$(GITMODULES),pull-$(mod))

src/%:
	mkdir -p $(dir $@)
	echo $* | sed -e 's|/|:|' | xargs -I{} git clone git@{} $@

pull-src/%:
	cd src/$* && git pull

install: $(TARGET)
	go get -u -v github.com/golang/dep/cmd/...
	go get -u -v golang.org/x/tools/gopls
	go get -u -v github.com/sourcegraph/go-langserver

$(HOME)/.%:
	ln -s `pwd`/$* $@

$(HOME)/.fzf: $(FZF)
	ln -s `pwd`/$< $@

$(HOME)/.fzf.zsh: $(HOME)/.fzf
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

$(HOME)/.vim/autoload/plug.vim: $(VIM_PLUG)
	mkdir -p $(dir $@)
	ln -sf `pwd`/$</plug.vim $@

$(HOME)/.config/nvim/init.vim: vimrc
	mkdir -p $(dir $@)
	ln -sf `pwd`/$< $@

$(HOME)/.config/nvim/colors/molokai.vim: $(MOLOKAI)
	mkdir -p $(dir $@)
	ln -sf `pwd`/$</colors/molokai.vim $@

$(HOME)/.local/share/nvim/site/autoload/plug.vim: $(VIM_PLUG)
	mkdir -p $(dir $@)
	ln -sf `pwd`/$</plug.vim $@

$(HOME)/.goenv: $(GOENV)
	ln -sf `pwd`/$< $@

clean:
	rm -rf $(TARGET)

realclean: clean
	rm -rf src $(HOME)/.config/nvim/plugged

.PHONY: all pull-src/% install clean realclean

SRC = \
	zshrc \
	vimrc \
	screenrc \
	tmux.conf \
	perltidyrc \
	ocamlinit \
	gitconfig \
	gitignore_global \
	ctags

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
GOENV = src/github.com/syndbg/goenv

GITMODULES = $(VIM_PLUG) $(FZF) $(GOENV)

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
	ln -sf `pwd`/$</plug.vim $@

$(HOME)/.config/nvim/init.vim: vimrc
	mkdir -p $(dir $@)
	ln -sf `pwd`/$< $@

$(HOME)/.local/share/nvim/site/autoload/plug.vim: $(VIM_PLUG)
	mkdir -p $(dir $@)
	ln -sf `pwd`/$</plug.vim $@

$(HOME)/.goenv: $(GOENV)
	ln -sf `pwd`/$< $@

$(HOME)/go/bin/dep:
	#mkdir -p $(dir $@)
	#curl https://raw.githubusercontent.com/golang/dep/master/install.sh | INSTALL_DIRECTORY=$(dir $@) sh
	go get -u -v github.com/golang/dep/cmd/...

clean:
	rm -rf $(TARGET) $(HOME)/go/bin/dep

realclean: clean
	rm -rf src

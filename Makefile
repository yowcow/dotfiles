MINE := \
	ctags \
	gitconfig \
	gitignore_global \
	goenv.zsh \
	nodenv.zsh \
	ocamlinit \
	perltidyrc \
	screenrc \
	tmux.conf \
	vimrc \
	zshrc

THEIRS := \
	$(HOME)/.fzf \
	$(HOME)/.fzf.zsh \
	$(HOME)/.vim/autoload/plug.vim \
	$(HOME)/.config/nvim/init.vim \
	$(HOME)/.config/nvim/colors/molokai.vim \
	$(HOME)/.local/share/nvim/site/autoload/plug.vim \
	$(HOME)/.goenv \
	$(HOME)/.nodenv \
	$(HOME)/.nodenv/plugins/node-build \
	$(HOME)/.ctags.d/default.ctags

ALL_TARGETS = $(addprefix $(HOME)/.,$(MINE)) $(THEIRS)

FZF          := src/github.com/junegunn/fzf
GOENV        := src/github.com/syndbg/goenv
MOLOKAI      := src/github.com/tomasr/molokai
NODENV       := src/github.com/nodenv/nodenv
NODENV_BUILD := src/github.com/nodenv/node-build
VIM_PLUG     := src/github.com/junegunn/vim-plug

GIT_MODULES := \
	$(FZF) \
	$(GOENV) \
	$(MOLOKAI) \
	$(NODENV) \
	$(NODENV_BUILD) \
	$(VIM_PLUG)

all: update

update:
	make -j4 $(GIT_MODULES)
	make -j4 $(foreach mod,$(GIT_MODULES),pull-$(mod))
	make go-commands

src/%:
	mkdir -p $(dir $@)
	echo $* | sed -e 's|/|:|' | xargs -I{} git clone git@{} $@

pull-src/%:
	cd src/$* && git pull

go-commands:
ifneq ($(shell which go),)
	go get -u -v github.com/golang/dep/cmd/...
	go get -u -v golang.org/x/tools/gopls
	go get -u -v github.com/sourcegraph/go-langserver
else
	@echo "No go found in your PATH!!"
endif

install: $(ALL_TARGETS)

## Create symlink by default
$(HOME)/.%:
	ln -sfn `pwd`/$* $@

## For fzf
$(HOME)/.fzf: $(FZF)
	ln -sfn `pwd`/$< $@

$(HOME)/.fzf.zsh: $(HOME)/.fzf
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

## For vim
$(HOME)/.vim/autoload/plug.vim: $(VIM_PLUG)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$</plug.vim $@

$(HOME)/.config/nvim/init.vim: vimrc
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

## For neovim
$(HOME)/.config/nvim/colors/molokai.vim: $(MOLOKAI)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$</colors/molokai.vim $@

$(HOME)/.local/share/nvim/site/autoload/plug.vim: $(VIM_PLUG)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$</plug.vim $@

## For goenv
$(HOME)/.goenv: $(GOENV)
	ln -sfn `pwd`/$< $@

## For nodenv
$(HOME)/.nodenv: $(NODENV)
	ln -sfn `pwd`/$< $@

$(HOME)/.nodenv/plugins/node-build: $(NODENV_BUILD) $(HOME)/.nodenv
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

## For universal-ctags
$(HOME)/.ctags.d:
	mkdir -p $@

$(HOME)/.ctags.d/default.ctags: ctags $(HOME)/.ctags.d
	ln -sfn `pwd`/$< $@

clean:
	rm -rf $(ALL_TARGETS)

realclean: clean
	rm -rf src $(HOME)/.config/nvim/plugged

.PHONY: all update pull-src/% go-commands install clean realclean

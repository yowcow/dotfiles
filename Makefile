AUTO := \
	ctags \
	gitconfig \
	gitignore_global \
	goenv.zsh \
	nodenv.zsh \
	npm \
	npmrc \
	ocamlinit \
	perltidyrc \
	plenv.zsh \
	screenrc \
	tmux.conf \
	Xmodmap \
	Xresources \
	xprofile \
	zshrc

FULLPATHS := \
	$(HOME)/.fzf \
	$(HOME)/.fzf.zsh \
	$(HOME)/.config/alacritty/alacritty.yml \
	$(HOME)/.config/i3/config \
	$(HOME)/.config/nvim/init.vim \
	$(HOME)/.config/nvim/coc-settings.json \
	$(HOME)/.config/nvim/colors/molokai.vim \
	$(HOME)/.local/share/nvim/site/autoload/plug.vim \
	$(HOME)/.goenv \
	$(HOME)/.nodenv \
	$(HOME)/.nodenv/plugins/node-build \
	$(HOME)/.plenv \
	$(HOME)/.plenv/plugins/perl-build \
	$(HOME)/.ctags.d/default.ctags

ALLTARGETS = $(addprefix $(HOME)/.,$(AUTO)) $(FULLPATHS)

FZF          := src/github.com/junegunn/fzf
GOENV        := src/github.com/syndbg/goenv
MOLOKAI      := src/github.com/tomasr/molokai
NODENV       := src/github.com/nodenv/nodenv
NODENV_BUILD := src/github.com/nodenv/node-build
PLENV        := src/github.com/tokuhirom/plenv
PLENV_BUILD  := src/github.com/tokuhirom/Perl-Build
VIM_PLUG     := src/github.com/junegunn/vim-plug

GIT_MODULES := \
	$(FZF) \
	$(GOENV) \
	$(MOLOKAI) \
	$(NODENV) \
	$(NODENV_BUILD) \
	$(PLENV) \
	$(PLENV_BUILD) \
	$(VIM_PLUG)

all: update

update:
	make -j4 $(GIT_MODULES)
	make -j4 $(foreach mod,$(GIT_MODULES),pull-$(mod))

src/%:
	mkdir -p $(dir $@)
	echo $* | sed -e 's|/|:|' | xargs -I{} git clone git@{} $@

pull-src/%:
	cd src/$* && git pull

install: $(ALLTARGETS)

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

## For Alacritty
$(HOME)/.config/alacritty/alacritty.yml: alacritty.yml
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

## For i3wm
$(HOME)/.config/i3/config: i3-config
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

## For neovim
$(HOME)/.config/nvim/init.vim: init.vim
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

## For neovim
$(HOME)/.config/nvim/coc-settings.json: coc-settings.json
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

## For npm
$(HOME)/.npm:
	mkdir -p $@

# For plenv
$(HOME)/.plenv: $(PLENV)
	ln -sfn `pwd`/$< $@

$(HOME)/.plenv/plugins/perl-build: $(PLENV_BUILD) $(HOME)/.plenv
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

## For universal-ctags
$(HOME)/.ctags.d/default.ctags: ctags
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

clean:
	rm -rf $(ALLTARGETS)

realclean: clean
	rm -rf src $(HOME)/.config/nvim/plugged

.PHONY: all update pull-src/% install clean realclean

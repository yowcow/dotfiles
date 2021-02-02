TARGETS := \
	zshrc \
	config/alacritty/alacritty.yml \
	config/i3/config \
	config/nvim/init.vim \
	config/nvim/coc-settings.json \
	config/nvim/colors/molokai.vim \
	config/regolith/Xresources \
	ctags.d/default.ctags \
	fzf \
	fzf.zsh \
	gitconfig \
	gitignore_global \
	gnupg/gpg-agent.conf \
	goenv.zsh \
	goenv \
	local/share/nvim/site/autoload/plug.vim \
	nodenv \
	nodenv/plugins/node-build \
	nodenv.zsh \
	npmrc \
	ocamlinit \
	perltidyrc \
	plenv \
	plenv/plugins/perl-build \
	plenv.zsh \
	screenrc \
	tmux.conf \
	Xmodmap
	#Xresources \
	#xprofile \

FULLTARGETS = $(addprefix $(HOME)/.,$(TARGETS))

ERLANG_LS    := src/github.com/erlang-ls/erlang_ls
FZF          := src/github.com/junegunn/fzf
GOENV        := src/github.com/syndbg/goenv
MOLOKAI      := src/github.com/tomasr/molokai
NODENV       := src/github.com/nodenv/nodenv
NODENV_BUILD := src/github.com/nodenv/node-build
PLENV        := src/github.com/tokuhirom/plenv
PLENV_BUILD  := src/github.com/tokuhirom/Perl-Build
VIM_PLUG     := src/github.com/junegunn/vim-plug
ZLS          := src/github.com/zigtools/zls

GITMODULES := \
	$(ERLANG_LS) \
	$(FZF) \
	$(GOENV) \
	$(MOLOKAI) \
	$(NODENV) \
	$(NODENV_BUILD) \
	$(PLENV) \
	$(PLENV_BUILD) \
	$(VIM_PLUG) \
	$(ZLS)

ifeq ($(shell make -v | head -n1 | cut -d' ' -f3 | cut -d'.' -f1),3)
MAKE := make
else
MAKE := make -O
endif

all:

update:
	+$(MAKE) update/gitmodules
	+$(MAKE) update/lsp
	+$(MAKE) update/neovim

update/gitmodules: $(HOME)/.gitconfig
	+$(MAKE) -j4 $(addprefix update/,$(GITMODULES))

update/lsp:
	+$(MAKE) -j4 $(addprefix $@/,erlang golang node ziglang)

update/lsp/golang:
	if which go; then \
		go get -u golang.org/x/tools/gopls; \
		go get -u golang.org/x/lint/golint; \
	fi

update/lsp/node:
	if which npm; then \
		npm -g install \
			diagnostic-languageserver \
			intelephense \
			typescript \
			yarn; \
	fi

update/lsp/ziglang: $(ZLS)
	if which zig; then \
		mkdir -p $(HOME)/.local/bin && \
		cd $< && \
		zig build --prefix $(HOME)/.local; \
	fi

update/lsp/erlang: $(ERLANG_LS)
	if which rebar3; then \
		mkdir -p $(HOME)/.local/bin && \
		$(MAKE) -C $< && \
		cp $</_build/default/bin/erlang_ls $(HOME)/.local/bin/; \
	fi

update/neovim: update/neovim/pip3 update/neovim/pip update/neovim/gem update/neovim/npm

update/neovim/pip3:
	if which pip3; then \
		pip3 install --upgrade pynvim msgpack; \
	fi

update/neovim/pip:
	if which pip; then \
		pip install --upgrade neovim pynvim msgpack; \
	fi

update/neovim/gem:
	if which gem; then \
		gem install --user-install neovim; \
	fi

update/neovim/npm:
	if which npm; then \
		npm i -g neovim; \
	fi

src/%:
	mkdir -p $(dir $@)
	echo $* | sed -e 's|/|:|' | xargs -I{} git clone --recurse-submodules git@{} $@

update/src/%: src/%
	cd src/$* && git pull && git submodule update --init

install: $(FULLTARGETS)

clean:
	rm -rf $(FULLTARGETS)

realclean: clean
	rm -rf src $(HOME)/.config/nvim/plugged

.PHONY: all install update update/* clean realclean


## Create symlink by default
$(HOME)/.%: %
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$* $@


## For fzf
$(HOME)/.fzf: $(FZF)
	ln -sfn `pwd`/$< $@

$(HOME)/.fzf.zsh: $(HOME)/.fzf
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc


### For neovim
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


## For plenv
$(HOME)/.plenv: $(PLENV)
	ln -sfn `pwd`/$< $@

$(HOME)/.plenv/plugins/perl-build: $(PLENV_BUILD) $(HOME)/.plenv
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

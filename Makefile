TARGETS := \
	zshrc \
	config/alacritty/alacritty.yml \
	config/i3/config \
	config/i3blocks/config \
	config/nvim/init.vim \
	config/nvim/coc-settings.json \
	config/nvim/colors/molokai.vim \
	config/kanshi/config \
	config/sway/config \
	config/waybar/config \
	config/waybar/style.css \
	ctags.d/default.ctags \
	fzf \
	fzf.zsh \
	gitconfig \
	gitignore_global \
	gnupg/gpg.conf \
	gnupg/gpg-agent.conf \
	goenv.zsh \
	goenv \
	local/share/nvim/site/autoload/plug.vim \
	nodenv \
	nodenv/plugins/node-build \
	nodenv.zsh \
	ocamlinit \
	perltidyrc \
	plenv \
	plenv/plugins/perl-build \
	plenv.zsh \
	screenrc \
	tmux.conf \
	Xmodmap \
	Xresources \
	xprofile

FULLTARGETS = $(addprefix $(HOME)/.,$(TARGETS))

ERLANG_LS    := src/github.com/erlang-ls/erlang_ls
FZF          := src/github.com/junegunn/fzf
GOENV        := src/github.com/syndbg/goenv
I3BLOCKS     := src/github.com/vivien/i3blocks-contrib
MOLOKAI      := src/github.com/tomasr/molokai
NODENV       := src/github.com/nodenv/nodenv
NODENV_BUILD := src/github.com/nodenv/node-build
PLENV        := src/github.com/tokuhirom/plenv
PLENV_BUILD  := src/github.com/tokuhirom/Perl-Build
VIM_PLUG     := src/github.com/junegunn/vim-plug

GITMODULES := \
	$(ERLANG_LS) \
	$(FZF) \
	$(GOENV) \
	$(I3BLOCKS) \
	$(MOLOKAI) \
	$(NODENV) \
	$(NODENV_BUILD) \
	$(PLENV) \
	$(PLENV_BUILD) \
	$(VIM_PLUG)

ifeq ($(shell make -v | head -n1 | cut -d' ' -f3 | cut -d'.' -f1),3)
MAKE := make
else
MAKE := make -O
endif

all:
	$(MAKE) install && $(MAKE) update

update:
	+$(MAKE) update/gitmodules
	+$(MAKE) update/langs

update/gitmodules: $(HOME)/.gitconfig
	+$(MAKE) -j4 $(addprefix update/,$(GITMODULES))

update/langs:
	+$(MAKE) -j4 $(addprefix $@/,erlang golang nodejs python3 python ruby)

update/langs/erlang: $(ERLANG_LS)
	if which rebar3; then \
		mkdir -p $(HOME)/.local/bin && \
		$(MAKE) -C $< && \
		cp $</_build/default/bin/erlang_ls $(HOME)/.local/bin/; \
	fi

GOTOOLS := \
	golang.org/x/lint/golint \
	golang.org/x/tools/cmd/goimports \
	golang.org/x/tools/gopls

update/langs/golang:
	if which go; then \
		for mod in $(GOTOOLS); do \
			go install $$mod@latest; \
			echo "installed: $$mod"; \
		done \
	fi

update/langs/nodejs:
	if which npm; then \
		npm -g install \
			diagnostic-languageserver \
			elm elm-test elm-format \
			@elm-tooling/elm-language-server \
			intelephense \
			neovim \
			npm \
			sql-formatter \
			sql-formatter-cli \
			typescript \
			yarn \
			; \
	fi

update/langs/python3:
	if which pip3; then \
		pip3 install --upgrade \
			pynvim \
			msgpack \
			sqlparse \
			yq \
			; \
	fi

update/langs/python:
	if which pip; then \
		pip install --upgrade \
			neovim \
			pynvim \
			msgpack \
			; \
	fi

update/langs/ruby:
	if which gem; then \
		gem install --user-install neovim; \
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

.PRECIOUS: src/%
.PHONY: all install update update/* clean realclean


## Create symlink by default
$(HOME)/.%: %
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$* $@


## For macOS Alacritty
ifeq ($(shell uname -s),Darwin)
$(HOME)/.config/alacritty/alacritty.yml: config/alacritty/alacritty.macos.yml
	ln -s `pwd`/$< $@
endif


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

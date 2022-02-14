TARGETS := \
	Xmodmap \
	Xresources \
	config/alacritty/alacritty.yml \
	config/i3/config \
	config/i3blocks/config \
	config/kanshi/config \
	config/nvim/after \
	config/nvim/init.lua \
	config/sway/config \
	config/waybar/config \
	config/waybar/style.css \
	config/wofi/style.css \
	ctags.d/default.ctags \
	fzf \
	fzf.zsh \
	gitconfig \
	gitignore_global \
	gnupg/gpg-agent.conf \
	gnupg/gpg.conf \
	goenv \
	goenv.zsh \
	local/bin/buf \
	local/share/nvim/site/pack/paqs/start/paq-nvim \
	nodenv \
	nodenv.zsh \
	nodenv/plugins/node-build \
	npmrc \
	ocamlinit \
	perltidyrc \
	plenv \
	plenv.zsh \
	plenv/plugins/perl-build \
	tmux.conf \
	xprofile

FULLTARGETS = $(addprefix $(HOME)/.,zshrc $(TARGETS))

ERLANG_LS    := src/github.com/erlang-ls/erlang_ls
ERLFMT       := src/github.com/whatsapp/erlfmt
FZF          := src/github.com/junegunn/fzf
GOENV        := src/github.com/syndbg/goenv
I3BLOCKS     := src/github.com/vivien/i3blocks-contrib
NODENV       := src/github.com/nodenv/nodenv
NODENV_BUILD := src/github.com/nodenv/node-build
PAQ_NVIM     := src/github.com/savq/paq-nvim
PLENV        := src/github.com/tokuhirom/plenv
PLENV_BUILD  := src/github.com/tokuhirom/Perl-Build

GITMODULES := \
	$(ERLANG_LS) \
	$(ERLFMT) \
	$(FZF) \
	$(GOENV) \
	$(I3BLOCKS) \
	$(NODENV) \
	$(NODENV_BUILD) \
	$(PAQ_NVIM) \
	$(PLENV) \
	$(PLENV_BUILD)

ifeq ($(shell make -v | head -n1 | cut -d' ' -f3 | cut -d'.' -f1),3)
MAKE := make
else
MAKE := make -O
endif

all:
	$(MAKE) install && $(MAKE) update

update:
	+$(MAKE) update/gitmodules
	+$(MAKE) update/lang

update/gitmodules: $(HOME)/.gitconfig
	+$(MAKE) -j4 $(addprefix update/,$(GITMODULES))

update/lang:
	+$(MAKE) -j4 $(addprefix $@/,erlang golang nodejs python3 python ruby)

update/lang/erlang: update/lang/erlang/erlang_ls update/lang/erlang/erlfmt

update/lang/erlang/erlang_ls: $(ERLANG_LS)
	if which rebar3; then \
		mkdir -p $(HOME)/.local/bin && \
		$(MAKE) -C $< && \
		cp $</_build/default/bin/erlang_ls $(HOME)/.local/bin/; \
	fi

update/lang/erlang/erlfmt: $(ERLFMT)
	if which rebar3; then \
		mkdir -p $(HOME)/.local/bin; \
		$(MAKE) -C $< release && \
		cp $</_build/release/bin/erlfmt $(HOME)/.local/bin/; \
	fi

GOTOOLS := \
	golang.org/x/tools/cmd/goimports \
	golang.org/x/tools/gopls \
	honnef.co/go/tools/cmd/staticcheck

update/lang/golang:
	if which go; then \
		for mod in $(GOTOOLS); do \
			go install $$mod@latest; \
			echo "installed: $$mod"; \
		done \
	fi

update/lang/nodejs:
	if which npm; then \
		npm -g install \
			@ansible/ansible-language-server \
			diagnostic-languageserver \
			eslint \
			elm elm-test elm-format \
			@elm-tooling/elm-language-server \
			intelephense \
			neovim \
			npm \
			sql-formatter \
			sql-formatter-cli \
			tree-sitter-cli \
			typescript typescript-language-server \
			vscode-langservers-extracted \
			yarn \
			; \
	fi

update/lang/python3:
	if which pip3; then \
		pip3 install --upgrade \
			pynvim \
			msgpack \
			sqlparse \
			yq \
			; \
	fi

update/lang/python:
	if which pip; then \
		pip install --upgrade \
			neovim \
			pynvim \
			msgpack \
			; \
	fi

update/lang/ruby:
	## WTF?? Do:
	## travis login --com --github-token XXXX
	if which gem; then \
		gem install --user-install --no-document \
			travis \
			neovim; \
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
	rm -rf src $(HOME)/.config/nvim $(HOME)/.local/share/nvim

.PRECIOUS: src/%
.PHONY: all install update update/* clean realclean


## For macOS Alacritty
ifeq ($(shell uname -s),Darwin)
$(HOME)/.config/alacritty/alacritty.yml: config/alacritty/alacritty.macos.yml
	ln -s `pwd`/$< $@
endif


## For fzf (should be called after ~/.zshrc)
$(HOME)/.fzf: $(FZF)
	ln -sfn `pwd`/$< $@

$(HOME)/.fzf.zsh: $(HOME)/.fzf
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc


### For neovim
$(HOME)/.local/share/nvim/site/pack/paqs/start/paq-nvim: $(PAQ_NVIM)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$</ $@


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
$(HOME)/.npmrc:
	echo 'prefix = $${HOME}/.npm' > $@


## For plenv
$(HOME)/.plenv: $(PLENV)
	ln -sfn `pwd`/$< $@

$(HOME)/.plenv/plugins/perl-build: $(PLENV_BUILD) $(HOME)/.plenv
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@


## For tools
$(HOME)/.local/bin/buf:
	mkdir -p $(dir $@)
	curl -L https://raw.githubusercontent.com/yowcow/buf/main/bin/buf.pl -o $@ \
		&& chmod +x $@


## By default, fallback to create symlink
$(HOME)/.%: %
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$* $@

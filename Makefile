SOURCES := \
	Xmodmap \
	Xresources \
	config/alacritty/alacritty.yml \
	config/alacritty-theme \
	config/i3/config \
	config/i3blocks/config \
	config/libskk \
	config/kanshi/config \
	config/nvim \
	config/sql-formatter/config.json \
	config/starship.toml \
	config/sway/config \
	config/waybar/config \
	config/waybar/style.css \
	config/weston.ini \
	config/wezterm/wezterm.lua \
	config/wofi/style.css \
	fzf \
	gitconfig \
	gitignore_global \
	gnupg/gpg-agent.conf \
	gnupg/gpg.conf \
	goenv \
	goenv.zsh \
	local/bin/btvol \
	local/bin/buf \
	local/bin/erlang_ls \
	local/bin/mylock \
	local/share/nvim/site/pack/paqs/start/paq-nvim \
	nodenv \
	nodenv.zsh \
	nodenv/plugins/node-build \
	npmrc \
	ocamlinit \
	tmux.conf \
	xprofile \
	zshrc

TARGETS := $(addprefix $(HOME)/.,$(SOURCES))

ALACRITTY_THEME := _modules/github.com/eendroroy/alacritty-theme
ERLANG_LS       := _modules/github.com/erlang-ls/erlang_ls
FZF             := _modules/github.com/junegunn/fzf
GOENV           := _modules/github.com/syndbg/goenv
I3BLOCKS        := _modules/github.com/vivien/i3blocks-contrib
NODENV          := _modules/github.com/nodenv/nodenv
NODENV_BUILD    := _modules/github.com/nodenv/node-build
PAQ_NVIM        := _modules/github.com/savq/paq-nvim
WOFI_ARC        := _modules/github.com/sachahjkl/wofi-arc-dark

GIT_MODULES := $(ALACRITTY_THEME) \
			   $(ERLANG_LS) \
			   $(FZF) \
			   $(GOENV) \
			   $(I3BLOCKS) \
			   $(NODENV) \
			   $(NODENV_BUILD) \
			   $(PAQ_NVIM) \
			   $(WOFI_ARC)

ifeq ($(shell make -v | head -1 | rev | cut -d' ' -f1 | rev | cut -d'.' -f1),3)
MAKE := make -j4
else
MAKE := make -j4 -O
endif

all:
	$(MAKE) install

install: $(TARGETS)
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

$(HOME)/.config/alacritty-theme: $(ALACRITTY_THEME)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

$(HOME)/.config/i3blocks/config: $(I3BLOCKS)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/config/i3blocks/config $@

$(HOME)/.config/wofi/style.css: $(WOFI_ARC)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$</style.css $@

$(HOME)/.fzf: $(FZF)
	ln -sfn `pwd`/$< $@

$(HOME)/.goenv: $(GOENV)
	ln -sfn `pwd`/$< $@

$(HOME)/.local/bin/buf:
	mkdir -p $(dir $@)
	curl -L https://raw.githubusercontent.com/yowcow/buf/main/bin/buf.pl -o $@ \
		&& chmod +x $@

$(HOME)/.local/bin/erlang_ls: $(ERLANG_LS) FORCE
	mkdir -p $(dir $@)
	if which rebar3 1>/dev/null; then \
		$(MAKE) -C $< && \
		cp $</_build/default/bin/erlang_ls $@; \
	fi

$(HOME)/.local/share/nvim/site/pack/paqs/start/paq-nvim: $(PAQ_NVIM)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$</ $@

$(HOME)/.nodenv: $(NODENV)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

$(HOME)/.nodenv/plugins/node-build: $(NODENV_BUILD)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

$(HOME)/.npmrc:
	echo 'prefix = $${HOME}/.npm' > $@

ifeq ($(shell uname),Darwin)
$(HOME)/.gnupg/gpg-agent.conf: gnupg/gpg-agent.darwin.conf
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@
endif

##
## Default Fallback
##
$(HOME)/.%: %
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$* $@

##
## Tasks
##
_modules/%:
	mkdir -p $(dir $@)
	git clone \
		--recurse-submodules \
		git@$$(echo $* | sed -e 's|/|:|') \
		$@

update:
	$(MAKE) $(addprefix update/,$(GIT_MODULES))
	$(MAKE) $(addprefix update/lang/,golang nodejs python3 rust)
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

update/_modules/%: FORCE $(HOME)/.gitconfig _modules/%
	git -C _modules/$* pull \
		&& git -C _modules/$* submodule sync --recursive \
		&& git -C _modules/$* submodule update --init --recursive

update/lang/golang: GOTOOLS := \
	golang.org/x/tools/cmd/goimports \
	golang.org/x/tools/gopls \
	honnef.co/go/tools/cmd/staticcheck \
	github.com/yowcow/ezserve
update/lang/golang: FORCE
	if which go 1>/dev/null; then \
		for mod in $(GOTOOLS); do \
			go install $$mod@latest; \
			echo "installed: $$mod"; \
		done \
	fi

update/lang/nodejs: FORCE
	if which npm 1>/dev/null; then \
		npm -g install \
			@ansible/ansible-language-server \
			@elm-tooling/elm-language-server \
			aws-cdk \
			elm \
			elm-format \
			elm-test \
			eslint \
			intelephense \
			neovim \
			npm \
			npm-check-updates \
			sql-formatter \
			sql-formatter-cli \
			tree-sitter-cli \
			typescript \
			typescript-language-server \
			vscode-langservers-extracted \
			yarn \
			; \
	fi

update/lang/python3: FORCE
	if which pipx 1>/dev/null; then \
		for pkg in qmk; do \
			(which $$pkg && pipx upgrade --include-injected $$pkg) || pipx install --include-deps $$pkg; \
		done \
	fi

update/lang/rust: FORCE
	if which rustup 1>/dev/null; then \
		rustup component add \
			rust-analyzer \
			rust-src \
			rustfmt \
			; \
		rustup update; \
	fi
	if which cargo 1>/dev/null; then \
		cargo install \
			cargo-update \
			; \
		cargo install-update -a; \
	fi

clean:
	rm -f $(TARGETS)

realclean: clean
	rm -rf _modules

FORCE:

.PHONY: all install update clean realclean

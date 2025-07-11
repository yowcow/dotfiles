TMPDIR = /tmp/dotfiles-tmp

MACHINE = $(shell uname -m)
ifeq ($(MACHINE),arm64)
	MACHINE = aarch64
endif

SOURCES := \
	Xmodmap \
	Xresources \
	config/alacritty/alacritty.toml \
	config/alacritty-theme \
	config/i3/config \
	config/i3blocks/config \
	config/lemonade.toml \
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
	config/zellij/config.kdl \
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
	local/bin/tmux \
	local/bin/vacuum \
	local/bin/zellij \
	local/google-cloud-sdk \
	local/share/nvim/site/autoload/plug.vim \
	luarocks.zsh \
	nvm \
	nvm.zsh \
	ocamlinit \
	plenv \
	plenv/plugins/perl-build \
	plenv.zsh \
	pyenv \
	pyenv.zsh \
	ripgreprc \
	tmux.conf \
	xprofile \
	zshrc

TARGETS := $(addprefix $(HOME)/.,$(SOURCES))

ALACRITTY_THEME := _modules/github.com/alacritty/alacritty-theme
ERLANG_LS       := _modules/github.com/erlang-ls/erlang_ls
FZF             := _modules/github.com/junegunn/fzf
VIMPLUG         := _modules/github.com/junegunn/vim-plug
GOENV           := _modules/github.com/go-nv/goenv
I3BLOCKS        := _modules/github.com/vivien/i3blocks-contrib
NVM             := _modules/github.com/nvm-sh/nvm
PLENV           := _modules/github.com/tokuhirom/plenv
PLENV_BUILD     := _modules/github.com/tokuhirom/Perl-Build
PYENV           := _modules/github.com/pyenv/pyenv
WOFI_ARC        := _modules/github.com/sachahjkl/wofi-arc-dark

GIT_MODULES := $(ALACRITTY_THEME) \
			   $(ERLANG_LS) \
			   $(FZF) \
			   $(GOENV) \
			   $(I3BLOCKS) \
			   $(NVM) \
			   $(PLENV) \
			   $(PLENV_BUILD) \
			   $(PYENV) \
			   $(VIMPLUG) \
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
	mkdir -p $(@D)
	ln -sfn `pwd`/$< $@

$(HOME)/.config/i3blocks/config: $(I3BLOCKS)
	mkdir -p $(@D)
	ln -sfn `pwd`/config/i3blocks/config $@

$(HOME)/.config/wofi/style.css: $(WOFI_ARC)
	mkdir -p $(@D)
	ln -sfn `pwd`/$</style.css $@

$(HOME)/.fzf: $(FZF)
	ln -sfn `pwd`/$< $@

$(HOME)/.goenv: $(GOENV)
	ln -sfn `pwd`/$< $@

$(HOME)/.local/bin/buf:
	mkdir -p $(@D)
	curl -L https://raw.githubusercontent.com/yowcow/buf/main/bin/buf.pl -o $@ \
		&& chmod +x $@

$(HOME)/.local/bin/erlang_ls: $(ERLANG_LS) FORCE
	mkdir -p $(@D)
	if command -v rebar3 1>/dev/null; then \
		$(MAKE) -C $< && \
		cp $</_build/default/bin/erlang_ls $@; \
	fi

.INTERMEDIATE: $(TMPDIR)/google-cloud-cli.tar.gz

$(HOME)/.local/google-cloud-sdk: $(TMPDIR)/google-cloud-cli.tar.gz
	tar -xzf $< -C $(HOME)/.local

$(TMPDIR)/google-cloud-cli.tar.gz: OS = $(shell [ "$$(uname -s)" = "Darwin" ] && echo "darwin" || echo "linux")
$(TMPDIR)/google-cloud-cli.tar.gz: ARCH = $(shell [ "$$(uname -p)" = "aarch64" ] && echo "arm" || uname -p)
$(TMPDIR)/google-cloud-cli.tar.gz:
	mkdir -p $(@D)
	curl -L https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-$(OS)-$(ARCH).tar.gz -o $@

TMUX_VERSION = 3.5a
.INTERMEDIATE: $(TMPDIR)/tmux-$(TMUX_VERSION) $(TMPDIR)/tmux-$(TMUX_VERSION).tar.gz

# ubuntu: libevent-dev libutf8proc-dev bison
# macOS: libevent pkg-config
$(HOME)/.local/bin/tmux: $(TMPDIR)/tmux-$(TMUX_VERSION)
	cd $< \
		&& ./configure \
			--enable-utf8proc \
			--prefix=$(HOME)/.local \
		&& make -j4 && make install
	touch $@

$(TMPDIR)/tmux-$(TMUX_VERSION): $(TMPDIR)/tmux-$(TMUX_VERSION).tar.gz
	tar -xzf $< -C $(@D)
	touch $@

$(TMPDIR)/tmux-%.tar.gz:
	mkdir -p $(@D)
	curl -L https://github.com/tmux/tmux/releases/download/$*/tmux-$*.tar.gz -o $@

ZELLIJ_VERSION = v0.41.1
.INTERMEDIATE: $(TMPDIR)/zellij-$(ZELLIJ_VERSION).tar.gz

$(HOME)/.local/bin/zellij: $(TMPDIR)/zellij-$(ZELLIJ_VERSION).tar.gz
	tar -xzf $< -C $(@D)
	touch $@

$(TMPDIR)/zellij-%.tar.gz:
ifeq ($(shell uname -s),Darwin)
$(TMPDIR)/zellij-%.tar.gz: URL = https://github.com/zellij-org/zellij/releases/download/$*/zellij-$(MACHINE)-apple-darwin.tar.gz
else
$(TMPDIR)/zellij-%.tar.gz: URL = https://github.com/zellij-org/zellij/releases/download/$*/zellij-$(MACHINE)-unknown-linux-musl.tar.gz
endif
$(TMPDIR)/zellij-%.tar.gz:
	mkdir -p $(@D)
	curl -L $(URL) -o $@

$(HOME)/.local/share/nvim/site/autoload/plug.vim: $(VIMPLUG)
	mkdir -p $(@D)
	ln -sfn `pwd`/$</plug.vim $@

$(HOME)/.nvm: $(NVM)
	ln -sfn `pwd`/$< $@

$(HOME)/.plenv: $(PLENV)
	ln -sfn `pwd`/$< $@

$(HOME)/.plenv/plugins/perl-build: $(PLENV_BUILD) $(HOME)/.plenv
	mkdir -p $(@D)
	ln -sfn `pwd`/$< $@

$(HOME)/.pyenv: $(PYENV)
	ln -sfn `pwd`/$< $@

ifeq ($(shell uname),Darwin)
$(HOME)/.gnupg/gpg-agent.conf: gnupg/gpg-agent.darwin.conf
	mkdir -p $(@D)
	ln -sfn `pwd`/$< $@
endif

##
## Default Fallback
##
$(HOME)/.%: %
	mkdir -p $(@D)
	ln -sfn `pwd`/$* $@

##
## Tasks
##
_modules/%:
	mkdir -p $(@D)
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
	github.com/google/yamlfmt/cmd/yamlfmt@latest \
	github.com/lemonade-command/lemonade@latest \
	github.com/yowcow/ezserve@latest \
	golang.org/x/tools/cmd/goimports@latest \
	golang.org/x/tools/gopls@latest \
	google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest \
	google.golang.org/protobuf/cmd/protoc-gen-go@latest \
	honnef.co/go/tools/cmd/staticcheck@latest
update/lang/golang: FORCE
	if command -v go 1>/dev/null; then \
		for mod in $(GOTOOLS); do \
			go install $$mod; \
			echo "installed: $$mod"; \
		done; \
		goenv rehash; \
	fi

update/lang/nodejs: FORCE
	if command -v npm 1>/dev/null; then \
		npm -g install \
			@ansible/ansible-language-server \
			@anthropic-ai/claude-code \
			@google/gemini-cli \
			@vue/language-server \
			aws-cdk \
			eslint \
			intelephense \
			neovim \
			npm \
			npm-check-updates \
			opencode-ai \
			perlnavigator-server \
			prettier \
			pyright \
			sql-formatter \
			sql-formatter-cli \
			tree-sitter-cli \
			typescript \
			typescript-language-server \
			vls \
			vscode-langservers-extracted \
			yarn \
			; \
	fi

update/lang/python3: FORCE
	if command -v pipx 1>/dev/null; then \
		for pkg in ansible qmk ninja pre-commit python-lsp-server pylint shandy-sqlfmt llama-stack; do \
			pipx upgrade --include-injected $$pkg || pipx install --include-deps $$pkg; \
		done \
	fi

update/lang/rust: FORCE
	if command -v rustup 1>/dev/null; then \
		rustup component add \
			rust-analyzer \
			rust-src \
			rustfmt \
			; \
		rustup update; \
	fi
	if command -v cargo 1>/dev/null; then \
		cargo install \
			cargo-update \
			efmt \
			starship \
			stylua \
			; \
		cargo install-update -a; \
	fi

clean:
	rm -f $(TARGETS)

realclean: clean
	rm -rf _modules

FORCE:

.PHONY: all install update clean realclean

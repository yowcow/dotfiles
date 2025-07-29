DOTFILES_TMPDIR = /tmp/dotfiles-tmp

MACHINE := $(shell uname -m)
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
	docker/cli-plugins/docker-mcp \
	fzf \
	gitconfig \
	gitignore_global \
	gnupg/gpg-agent.conf \
	gnupg/gpg.conf \
	goenv \
	goenv.zsh \
	local/bin/aws-vault \
	local/bin/btvol \
	local/bin/buf \
	local/bin/kerl \
	local/bin/rebar3 \
	local/bin/erlang_ls \
	local/bin/mylock \
	local/bin/tmux \
	local/bin/update-env \
	local/bin/vacuum \
	local/bin/zellij \
	local/share/nvim/site/autoload/plug.vim \
	luarocks.zsh \
	nvm \
	nvm.zsh \
	ocamlinit \
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
PYENV           := _modules/github.com/pyenv/pyenv
WOFI_ARC        := _modules/github.com/sachahjkl/wofi-arc-dark

GIT_MODULES := $(ALACRITTY_THEME) \
			   $(ERLANG_LS) \
			   $(FZF) \
			   $(GOENV) \
			   $(I3BLOCKS) \
			   $(NVM) \
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

##
## https://github.com/ByteNess/aws-vault/releases
##
AWS_VAULT_VERSION = v7.5.5

$(HOME)/.local/bin/aws-vault: OS = $(shell uname -s | tr '[A-Z]' '[a-z]')
ifeq ($(MACHINE),aarch64)
$(HOME)/.local/bin/aws-vault: ARCH = arm64
else ifeq ($(MACHINE),x86_64)
$(HOME)/.local/bin/aws-vault: ARCH = amd64
else
$(HOME)/.local/bin/aws-vault: ARCH = $(shell uname -p)
endif
$(HOME)/.local/bin/aws-vault:
	curl -L "https://github.com/ByteNess/aws-vault/releases/download/$(AWS_VAULT_VERSION)/aws-vault-$(OS)-$(ARCH)" -o $@
	chmod a+x $@

##
## https://github.com/docker/mcp-gateway/releases
##
DOCKER_MCP_VERSION = v0.13.0

$(HOME)/.docker/cli-plugins/docker-mcp: OS = $(shell uname -s | tr '[A-Z]' '[a-z]')
ifeq ($(MACHINE),aarch64)
$(HOME)/.docker/cli-plugins/docker-mcp: ARCH = arm64
else ifeq ($(MACHINE),x86_64)
$(HOME)/.docker/cli-plugins/docker-mcp: ARCH = amd64
else
$(HOME)/.docker/cli-plugins/docker-mcp: ARCH = $(shell uname -p)
endif
$(HOME)/.docker/cli-plugins/docker-mcp:
	mkdir -p $(@D)
	curl -L "https://github.com/docker/mcp-gateway/releases/download/$(DOCKER_MCP_VERSION)/docker-mcp-$(OS)-$(ARCH).tar.gz" | tar -xz -C $(@D)

##
## kerl
##
$(HOME)/.local/bin/kerl:
	curl -L https://raw.githubusercontent.com/kerl/kerl/master/kerl -o $@
	chmod a+x $@

##
## https://github.com/erlang/rebar3/releases
##
REBAR3_VERSION = 3.25.1

$(HOME)/.local/bin/rebar3:
	curl -L https://github.com/erlang/rebar3/releases/download/$(REBAR3_VERSION)/rebar3 -o $@
	chmod a+x $@

##
## https://github.com/tmux/tmux/releases
##
TMUX_VERSION = 3.5a
.INTERMEDIATE: $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION) $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION).tar.gz

# ubuntu: libevent-dev libutf8proc-dev bison
# macOS: libevent pkg-config
$(HOME)/.local/bin/tmux: $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION)
	cd $< \
		&& ./configure \
			--enable-utf8proc \
			--prefix=$(HOME)/.local \
		&& $(MAKE) && $(MAKE) install
	touch $@

$(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION): $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION).tar.gz
	tar -xzf $< -C $(@D)
	touch $@

$(DOTFILES_TMPDIR)/tmux-%.tar.gz:
	mkdir -p $(@D)
	curl -L https://github.com/tmux/tmux/releases/download/$*/tmux-$*.tar.gz -o $@

##
## https://github.com/zellij-org/zellij/releases
##
ZELLIJ_VERSION = v0.42.2
.INTERMEDIATE: $(DOTFILES_TMPDIR)/zellij-$(ZELLIJ_VERSION).tar.gz

$(HOME)/.local/bin/zellij: $(DOTFILES_TMPDIR)/zellij-$(ZELLIJ_VERSION).tar.gz
	tar -xzf $< -C $(@D)
	touch $@

$(DOTFILES_TMPDIR)/zellij-%.tar.gz:
ifeq ($(shell uname -s),Darwin)
$(DOTFILES_TMPDIR)/zellij-%.tar.gz: URL = https://github.com/zellij-org/zellij/releases/download/$*/zellij-$(MACHINE)-apple-darwin.tar.gz
else
$(DOTFILES_TMPDIR)/zellij-%.tar.gz: URL = https://github.com/zellij-org/zellij/releases/download/$*/zellij-$(MACHINE)-unknown-linux-musl.tar.gz
endif
$(DOTFILES_TMPDIR)/zellij-%.tar.gz:
	mkdir -p $(@D)
	curl -L $(URL) -o $@

$(HOME)/.local/share/nvim/site/autoload/plug.vim: $(VIMPLUG)
	mkdir -p $(@D)
	ln -sfn `pwd`/$</plug.vim $@

$(HOME)/.nvm: $(NVM)
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
			@modelcontextprotocol/inspector \
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
		for pkg in ansible qmk ninja pre-commit python-lsp-server pylint shandy-sqlfmt uv llama-stack; do \
			pipx upgrade --include-injected $$pkg || pipx install --include-deps $$pkg; \
		done \
	fi

update/lang/rust: FORCE
	if command -v rustup 1>/dev/null; then \
		rustup update; \
		rustup component add \
			rust-analyzer \
			rust-src \
			rustfmt \
			; \
	fi
	if command -v cargo 1>/dev/null; then \
		cargo install \
			cargo-update \
			efmt \
			stylua \
			; \
		cargo install-update -a; \
	fi

clean/versioned: FORCE
	rm -f \
		$(HOME)/.docker/cli-plugins/docker-mcp \
		$(HOME)/.local/bin/aws-vault \
		$(HOME)/.local/bin/kerl \
		$(HOME)/.local/bin/tmux \
		$(HOME)/.local/bin/zellij

clean:
	rm -f $(TARGETS)

realclean: clean
	rm -rf _modules

FORCE:

.PHONY: all install update clean realclean

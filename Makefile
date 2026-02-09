DOTFILES_TMPDIR = /tmp/dotfiles-tmp

MACHINE := $(shell uname -m)
ifeq ($(MACHINE),arm64)
MACHINE = aarch64
endif

SOURCES := \
	Xmodmap \
	Xresources \
	claude/CLAUDE.md \
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
	docker/cli-plugins/docker-buildx \
	docker/cli-plugins/docker-mcp \
	fzf \
	gemini/GEMINI.md \
	gitconfig \
	gitignore_global \
	gnupg/gpg-agent.conf \
	gnupg/gpg.conf \
	goenv \
	goenv.zsh \
	local/bin/aws-vault \
	local/bin/btvol \
	local/bin/buf.pl \
	local/bin/kerl \
	local/bin/rebar3 \
	local/bin/erlang_ls \
	local/bin/mylock \
	local/bin/tmux \
	local/bin/update-env \
	local/bin/vacuum \
	local/bin/zellij \
	luarocks.zsh \
	nvm \
	nvm.zsh \
	ocamlinit \
	perltidyrc \
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

$(HOME)/.local/bin/buf.pl:
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
AWS_VAULT_VERSION = v7.8.2

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
## https://github.com/docker/buildx/releases
##
DOCKER_BUILDX_VERSION = v0.30.1

$(HOME)/.docker/cli-plugins/docker-buildx: OS = $(shell uname -s | tr '[A-Z]' '[a-z]')
ifeq ($(MACHINE),aarch64)
$(HOME)/.docker/cli-plugins/docker-buildx: ARCH = arm64
else ifeq ($(MACHINE),x86_64)
$(HOME)/.docker/cli-plugins/docker-buildx: ARCH = amd64
else
$(HOME)/.docker/cli-plugins/docker-buildx: ARCH = $(shell uname -p)
endif
$(HOME)/.docker/cli-plugins/docker-buildx:
	mkdir -p $(@D)
	curl -L "https://github.com/docker/buildx/releases/download/$(DOCKER_BUILDX_VERSION)/buildx-$(DOCKER_BUILDX_VERSION).$(OS)-$(ARCH)" -o $@
	chmod a+x $@

##
## https://github.com/docker/mcp-gateway/releases
##
DOCKER_MCP_VERSION = v0.32.0

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
## https://github.com/kerl/kerl/releases
##
$(HOME)/.local/bin/kerl:
	curl -L https://raw.githubusercontent.com/kerl/kerl/master/kerl -o $@
	chmod a+x $@

##
## https://github.com/erlang/rebar3/releases
##
REBAR3_VERSION = 3.24.0

$(HOME)/.local/bin/rebar3:
	curl -L https://github.com/erlang/rebar3/releases/download/$(REBAR3_VERSION)/rebar3 -o $@
	chmod a+x $@

##
## https://github.com/tmux/tmux/releases
##
TMUX_VERSION = 3.6a
.INTERMEDIATE: $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION) $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION).tar.gz

# ubuntu: libevent-dev libutf8proc-dev bison
# macOS: libevent pkg-config
$(HOME)/.local/bin/tmux: $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION)
	cd $< \
		&& autoreconf -f -i \
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
ZELLIJ_VERSION = v0.43.1
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
	$(MAKE) update/docker
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

update/_modules/%: FORCE $(HOME)/.gitconfig _modules/%
	git -C _modules/$* pull \
		&& git -C _modules/$* submodule sync --recursive \
		&& git -C _modules/$* submodule update --init --recursive

update/lang/golang: GOTOOLS := \
	github.com/bufbuild/buf/cmd/buf@latest \
	github.com/google/yamlfmt/cmd/yamlfmt@latest \
	github.com/lemonade-command/lemonade@latest \
	github.com/suzuki-shunsuke/pinact/cmd/pinact@latest \
	github.com/yowcow/ezserve@latest \
	golang.org/x/tools/cmd/goimports@latest \
	golang.org/x/tools/gopls@latest \
	google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest \
	google.golang.org/protobuf/cmd/protoc-gen-go@latest \
	honnef.co/go/tools/cmd/staticcheck@latest
update/lang/golang: FORCE
	@if command -v go >/dev/null; then \
		echo "Updating Go tools..."; \
		go install $(GOTOOLS); \
		if command -v goenv >/dev/null; then goenv rehash; fi; \
	fi

update/lang/nodejs: NPMPKGS := \
	@google/gemini-cli \
	@modelcontextprotocol/inspector \
	aws-cdk \
	neovim \
	npm \
	npm-check-updates \
	prettier \
	sql-formatter \
	sql-formatter-cli \
	typescript \
	yarn
update/lang/nodejs: FORCE
	@if command -v npm >/dev/null; then \
		echo "Updating Node.js packages..."; \
		npm install -g $(NPMPKGS); \
	fi

update/lang/python3: PIPXPKGS := \
	ansible \
	ninja \
	pre-commit \
	qmk \
	shandy-sqlfmt \
	uv
update/lang/python3: FORCE
	@if command -v pipx >/dev/null; then \
		echo "Updating Python tools..."; \
		for pkg in $(PIPXPKGS); do \
			pipx upgrade --include-injected $$pkg || pipx install --include-deps $$pkg; \
		done; \
	fi

update/lang/rust: RUSTUP_COMPONENTS := \
	rust-analyzer \
	rust-src \
	rustfmt
update/lang/rust: CARGO_PKGS := \
	cargo-update \
	efmt \
	stylua
update/lang/rust: FORCE
	@if command -v rustup >/dev/null; then \
		echo "Updating Rust toolchain..."; \
		rustup update; \
		rustup component add $(RUSTUP_COMPONENTS); \
	fi
	@if command -v cargo >/dev/null; then \
		echo "Updating Cargo packages..."; \
		cargo install $(CARGO_PKGS); \
		cargo install-update -a; \
	fi

VERSIONED_TARGETS := \
		$(HOME)/.docker/cli-plugins/docker-buildx \
		$(HOME)/.docker/cli-plugins/docker-mcp \
		$(HOME)/.local/bin/aws-vault \
		$(HOME)/.local/bin/rebar3 \
		$(HOME)/.local/bin/kerl \
		$(HOME)/.local/bin/tmux \
		$(HOME)/.local/bin/zellij

clean/versioned: FORCE
	rm -f $(VERSIONED_TARGETS) $(HOME)/.local/bin/erlang_ls

install/versioned: $(VERSIONED_TARGETS)
	$(MAKE) $(HOME)/.local/bin/erlang_ls

update/docker: DOCKER_IMAGES := \
	mcp/aws-documentation \
	mcp/fetch \
	mcp/github \
	mcp/time \
	mcp/wikipedia-mcp
update/docker: FORCE
	@if command -v docker >/dev/null; then \
		echo "Pulling Docker images..."; \
		for image in $(DOCKER_IMAGES); do \
			docker pull $$image; \
		done; \
	fi


clean:
	rm -f $(TARGETS)

realclean: clean
	rm -rf _modules

FORCE:

.PHONY: all install update clean realclean install/versioned clean/versioned \
		update/lang/golang update/lang/nodejs update/lang/python3 update/lang/rust \
		update/docker

install/lang/golang: GOTOOLS := \
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
install/lang/golang:
	@if command -v go >/dev/null; then \
		echo "Installing Go tools..."; \
		for p in $(GOTOOLS); do go install $$p; done; \
		if command -v goenv >/dev/null; then goenv rehash; fi; \
	fi

update/lang/golang: install/lang/golang
	@if command -v go >/dev/null; then \
		go clean -cache; \
		go clean -modcache; \
	fi

# npm -g is used only to bootstrap npm + pnpm; everything else goes to pnpm global.
install/lang/nodejs: NPM_PKGS := npm pnpm
# tools managed by pnpm global (npm, yarn removed from the old bulk list)
install/lang/nodejs: PNPM_PKGS := \
	@google/gemini-cli \
	@modelcontextprotocol/inspector \
	@opencode/cli \
	aws-cdk \
	neovim \
	npm-check-updates \
	prettier \
	sql-formatter \
	sql-formatter-cli \
	typescript
# packages whose build scripts must be allowed (carried over from NPM_ALLOW_SCRIPTS, minus yarn)
install/lang/nodejs: PNPM_ALLOW_BUILD := @opencode/cli @modelcontextprotocol/inspector @github/keytar node-pty
# pinned MCP, keep out of unpinned PNPM_PKGS
install/lang/nodejs: DBHUB_VERSION := 1.5.0
install/lang/nodejs:
	@if command -v npm >/dev/null; then \
		echo "Installing Node.js packages..."; \
		set -e; \
		export PNPM_HOME="$$HOME/.local/share/pnpm"; \
		export PATH="$$PNPM_HOME/bin:$$PATH"; \
		# corepack's pnpm shim in the prefix bin makes npm -g pnpm fail with EEXIST \
		if command -v corepack >/dev/null; then corepack disable pnpm; fi; \
		# 1. active prefix: bootstrap npm + pnpm via npm -g (flags are per-invocation, not written to npmrc) \
		npm install -g --allow-remote=all --allow-scripts=pnpm $(NPM_PKGS); \
		# 2. tools + pinned dbhub via pnpm global \
		pnpm add -g $(foreach p,$(PNPM_ALLOW_BUILD),--allow-build=$(p)) $(PNPM_PKGS) @bytebase/dbhub@$(DBHUB_VERSION); \
	fi

update/lang/nodejs: install/lang/nodejs
	@if command -v npm >/dev/null; then \
		set -e; \
		export PNPM_HOME="$$HOME/.local/share/pnpm"; \
		export PATH="$$PNPM_HOME/bin:$$PATH"; \
		# cache cleanup \
		npm cache clean --force; \
		pnpm store prune; \
	fi

install/lang/python3: PIPXPKGS := \
	ansible \
	ninja \
	pre-commit \
	qmk \
	shandy-sqlfmt \
	uv
install/lang/python3: SERENA_PYTHON ?= 3.13
install/lang/python3: SERENA_VERSION := 1.7.0
install/lang/python3: UVTOOLS := \
	serena-agent==$(SERENA_VERSION)
install/lang/python3:
	@if command -v pipx >/dev/null; then \
		echo "Installing Python tools..."; \
		for pkg in $(PIPXPKGS); do \
			pipx upgrade --include-injected $$pkg || pipx install --include-deps $$pkg; \
		done; \
	fi
	@if command -v uv >/dev/null; then \
		echo "Installing uv tools..."; \
		for pkg in $(UVTOOLS); do \
			uv tool install -p $(SERENA_PYTHON) $$pkg; \
		done; \
	fi

update/lang/python3: install/lang/python3
	@if command -v uv >/dev/null; then \
		uv cache clean; \
	fi
	@if command -v pip >/dev/null; then \
		pip cache purge; \
	fi

install/lang/rust: RUSTUP_COMPONENTS := \
	rust-analyzer \
	rust-src \
	rustfmt
install/lang/rust: CARGO_PKGS := \
	cargo-update \
	efmt \
	stylua
install/lang/rust:
	@if command -v rustup >/dev/null; then \
		echo "Installing Rust toolchain..."; \
		rustup update; \
		rustup component add $(RUSTUP_COMPONENTS); \
	fi
	@if command -v cargo >/dev/null; then \
		echo "Installing Cargo packages..."; \
		cargo install $(CARGO_PKGS); \
		cargo install-update -a; \
	fi

update/lang/rust: install/lang/rust
	@if command -v cargo >/dev/null; then \
		rm -rf "$${CARGO_HOME:-$$HOME/.cargo}"/registry/cache/*; \
	fi

install/docker: DOCKER_IMAGES := \
	mcp/aws-documentation \
	mcp/fetch \
	mcp/github \
	mcp/time \
	mcp/wikipedia-mcp
install/docker:
	@if command -v docker >/dev/null; then \
		echo "Pulling Docker images..."; \
		for image in $(DOCKER_IMAGES); do \
			docker pull $$image; \
		done; \
	fi

update/docker: install/docker
	@if command -v docker >/dev/null; then \
		echo "Cleaning up Docker..."; \
		docker system prune -f; \
		docker volume prune -f; \
	fi

##
## codex / grok / muse / claude: self-update type. install/X runs the official
## installer; update/X keeps the tool's own update command, and `make update`
## calls only update/X. Override a script URL with make <NAME>_INSTALL_URL=<url>.
##
CODEX_INSTALL_URL  ?= https://chatgpt.com/codex/install.sh
GROK_INSTALL_URL   ?= https://x.ai/cli/install.sh
MUSE_INSTALL_URL   ?= https://dev.meta.ai/install.sh
CLAUDE_INSTALL_URL ?= https://claude.ai/install.sh

install/codex:
	@echo "Installing Codex CLI..."
	@tmpdir=$$(mktemp -d); trap 'rm -rf "$$tmpdir"' EXIT; \
	curl -fsSL "$(CODEX_INSTALL_URL)" -o "$$tmpdir/install.sh" \
		&& test -s "$$tmpdir/install.sh" \
		|| { echo "codex: failed to fetch a non-empty install script from $(CODEX_INSTALL_URL)" >&2; exit 1; }; \
	sh "$$tmpdir/install.sh"

update/codex: FORCE
	@echo "Updating Codex CLI..."
	@if command -v codex >/dev/null; then \
		codex update \
			|| echo "Codex CLI update skipped (no new release?)."; \
	else \
		echo "Codex CLI not installed, skipping."; \
	fi

install/grok:
	@echo "Installing Grok CLI..."
	@tmpdir=$$(mktemp -d); trap 'rm -rf "$$tmpdir"' EXIT; \
	curl -fsSL "$(GROK_INSTALL_URL)" -o "$$tmpdir/install.sh" \
		&& test -s "$$tmpdir/install.sh" \
		|| { echo "grok: failed to fetch a non-empty install script from $(GROK_INSTALL_URL)" >&2; exit 1; }; \
	bash "$$tmpdir/install.sh"

update/grok: FORCE
	@echo "Updating Grok CLI..."
	@if command -v grok >/dev/null; then \
		grok update \
			|| echo "Grok CLI update skipped (no new release?)."; \
	else \
		echo "Grok CLI not installed, skipping."; \
	fi

install/muse:
	@echo "Installing Muse Code..."
	@tmpdir=$$(mktemp -d); trap 'rm -rf "$$tmpdir"' EXIT; \
	curl -fsSL "$(MUSE_INSTALL_URL)" -o "$$tmpdir/install.sh" \
		&& test -s "$$tmpdir/install.sh" \
		|| { echo "muse: failed to fetch a non-empty install script from $(MUSE_INSTALL_URL)" >&2; exit 1; }; \
	bash "$$tmpdir/install.sh"

# Muse Code (Meta): https://dev.meta.ai/docs/muse-code
# Official launcher sync (`MUSE_SYNC_UPDATE`); `--version` avoids the TUI.
update/muse: FORCE
	@echo "Updating Muse Code..."
	@if command -v muse >/dev/null; then \
		MUSE_SYNC_UPDATE=1 muse --version \
			|| echo "Muse Code update skipped (no new release?)."; \
	else \
		echo "Muse Code not installed, skipping."; \
	fi

install/claude:
	@echo "Installing Claude CLI..."
	@tmpdir=$$(mktemp -d); trap 'rm -rf "$$tmpdir"' EXIT; \
	curl -fsSL "$(CLAUDE_INSTALL_URL)" -o "$$tmpdir/install.sh" \
		&& test -s "$$tmpdir/install.sh" \
		|| { echo "claude: failed to fetch a non-empty install script from $(CLAUDE_INSTALL_URL)" >&2; exit 1; }; \
	bash "$$tmpdir/install.sh"

update/claude: FORCE
	@echo "Updating Claude CLI..."
	@if command -v claude >/dev/null; then \
		claude update \
			|| echo "Claude CLI update skipped (no new release?)."; \
	else \
		echo "Claude CLI not installed, skipping."; \
	fi

.PHONY: install/lang/golang install/lang/nodejs install/lang/python3 install/lang/rust install/docker install/codex install/grok install/muse install/claude update/lang/golang update/lang/nodejs update/lang/python3 update/lang/rust update/docker update/codex update/grok update/muse update/claude

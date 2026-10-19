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
		for p in $(GOTOOLS); do go install $$p; done; \
		go clean -cache; \
		go clean -modcache; \
		if command -v goenv >/dev/null; then goenv rehash; fi; \
	fi

# npm -g is used only to bootstrap npm + pnpm; everything else goes to pnpm global.
update/lang/nodejs: NPM_PKGS := npm pnpm
# tools managed by pnpm global (npm, yarn removed from the old bulk list)
update/lang/nodejs: PNPM_PKGS := \
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
update/lang/nodejs: PNPM_ALLOW_BUILD := @opencode/cli @modelcontextprotocol/inspector @github/keytar node-pty
# pinned MCP, keep out of unpinned PNPM_PKGS
update/lang/nodejs: DBHUB_VERSION := 1.5.0
update/lang/nodejs: FORCE
	@if command -v npm >/dev/null; then \
		echo "Updating Node.js packages..."; \
		# 1. migration wipe: drop old npm globals from every nvm prefix, keep only the npm package \
		for prefix in $$HOME/.nvm/versions/node/*/; do \
			[ -d "$$prefix" ] || continue; \
			pkgs=$$(PATH="$$prefix/bin:$$PATH" npm list -g --depth=0 --parseable=true 2>/dev/null | sed -n 's|.*/node_modules/||p' | grep -v '^npm$$'); \
			if [ -n "$$pkgs" ]; then \
				PATH="$$prefix/bin:$$PATH" npm uninstall -g $$pkgs || true; \
			fi; \
		done; \
		set -e; \
		export PNPM_HOME="$$HOME/.local/share/pnpm"; \
		export PATH="$$PNPM_HOME/bin:$$PATH"; \
		# 2. active prefix: bootstrap npm + pnpm via npm -g (one-shot, not persisted) \
		npm install -g --allow-remote=all --allow-scripts=pnpm $(NPM_PKGS); \
		# 3. tools + pinned dbhub via pnpm global \
		pnpm add -g $(foreach p,$(PNPM_ALLOW_BUILD),--allow-build=$(p)) $(PNPM_PKGS) @bytebase/dbhub@$(DBHUB_VERSION); \
		# 4. cache cleanup \
		npm cache clean --force; \
		pnpm store prune; \
	fi

update/lang/python3: PIPXPKGS := \
	ansible \
	ninja \
	pre-commit \
	qmk \
	shandy-sqlfmt \
	uv
update/lang/python3: SERENA_PYTHON ?= 3.13
update/lang/python3: SERENA_VERSION := 1.7.0
update/lang/python3: UVTOOLS := \
	serena-agent==$(SERENA_VERSION)
update/lang/python3: FORCE
	@if command -v pipx >/dev/null; then \
		echo "Updating Python tools..."; \
		for pkg in $(PIPXPKGS); do \
			pipx upgrade --include-injected $$pkg || pipx install --include-deps $$pkg; \
		done; \
	fi
	@if command -v uv >/dev/null; then \
		echo "Updating uv tools..."; \
		for pkg in $(UVTOOLS); do \
			uv tool install -p $(SERENA_PYTHON) $$pkg; \
		done; \
		uv cache clean; \
	fi
	@if command -v pip >/dev/null; then \
		pip cache purge; \
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
		rm -rf "$${CARGO_HOME:-$$HOME/.cargo}"/registry/cache/*; \
	fi

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
		echo "Cleaning up Docker..."; \
		docker system prune -f; \
		docker volume prune -f; \
	fi

update/codex: FORCE
	@echo "Updating Codex CLI..."
	@if command -v codex >/dev/null; then \
		codex update \
			|| echo "Codex CLI update skipped (no new release?)."; \
	else \
		echo "Codex CLI not installed, skipping."; \
	fi

update/grok: FORCE
	@echo "Updating Grok CLI..."
	@if command -v grok >/dev/null; then \
		grok update \
			|| echo "Grok CLI update skipped (no new release?)."; \
	else \
		echo "Grok CLI not installed, skipping."; \
	fi

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

update/claude: FORCE
	@echo "Updating Claude CLI..."
	@if command -v claude >/dev/null; then \
		claude update \
			|| echo "Claude CLI update skipped (no new release?)."; \
	else \
		echo "Claude CLI not installed, skipping."; \
	fi

.PHONY: update/lang/golang update/lang/nodejs update/lang/python3 update/lang/rust update/docker update/codex update/grok update/muse update/claude

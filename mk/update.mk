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
		npm cache clean --force; \
	fi

update/lang/python3: PIPXPKGS := \
	ansible \
	ninja \
	pre-commit \
	qmk \
	shandy-sqlfmt \
	uv
update/lang/python3: SERENA_PYTHON ?= 3.13
update/lang/python3: UVTOOLS := \
	serena-agent
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

# NOTE: a total curl failure (e.g. network outage) leaves sh with empty
# stdin, which exits 0 -- so `|| echo` below won't even fire in that case.
# This is a known gap; only failures from within the installer itself
# (e.g. "no new release") are guaranteed to be caught.
update/codex: FORCE
	@echo "Updating Codex CLI..."
	curl -fsSL https://chatgpt.com/codex/install.sh \
		| CODEX_NON_INTERACTIVE=1 sh \
		|| echo "Codex CLI update skipped (no new release?)."

.PHONY: update/lang/golang update/lang/nodejs update/lang/python3 update/lang/rust update/docker update/codex

VERSIONED_TARGETS := \
		$(HOME)/.docker/cli-plugins/docker-buildx \
		$(HOME)/.docker/cli-plugins/docker-mcp \
		$(HOME)/.local/bin/aws-vault \
		$(HOME)/.local/bin/buf.pl \
		$(HOME)/.local/bin/rebar3 \
		$(HOME)/.local/bin/kerl \
		$(HOME)/.local/bin/tmux

install/versioned: $(VERSIONED_TARGETS)

clean/versioned: FORCE
	rm -f $(VERSIONED_TARGETS)

$(HOME)/.local/bin/buf.pl:
	mkdir -p $(@D)
	curl -fL https://raw.githubusercontent.com/yowcow/buf/main/bin/buf.pl -o $@ || { rm -f $@; exit 1; } \
		&& chmod +x $@

##
## https://github.com/ByteNess/aws-vault/releases
##
$(HOME)/.local/bin/aws-vault: OS = $(shell uname -s | tr '[A-Z]' '[a-z]')
ifeq ($(MACHINE),aarch64)
$(HOME)/.local/bin/aws-vault: ARCH = arm64
else ifeq ($(MACHINE),x86_64)
$(HOME)/.local/bin/aws-vault: ARCH = amd64
else
$(HOME)/.local/bin/aws-vault: ARCH = $(shell uname -p)
endif
$(HOME)/.local/bin/aws-vault:
	@url="$(call github-asset-url,ByteNess/aws-vault,aws-vault-$(OS)-$(ARCH),)"; test -n "$$url" || { echo "aws-vault: GitHub API lookup failed (empty asset URL); retry online" >&2; exit 1; }; \
	curl -fL "$$url" -o $@ || { rm -f $@; exit 1; }
	chmod a+x $@

##
## https://github.com/docker/buildx/releases
##
$(HOME)/.docker/cli-plugins/docker-buildx: OS = $(shell uname -s | tr '[A-Z]' '[a-z]')
ifeq ($(MACHINE),aarch64)
$(HOME)/.docker/cli-plugins/docker-buildx: ARCH = arm64
else ifeq ($(MACHINE),x86_64)
$(HOME)/.docker/cli-plugins/docker-buildx: ARCH = amd64
else
$(HOME)/.docker/cli-plugins/docker-buildx: ARCH = $(shell uname -p)
endif
$(HOME)/.docker/cli-plugins/docker-buildx:
	@url="$(call github-asset-url,docker/buildx,buildx-,.$(OS)-$(ARCH))"; test -n "$$url" || { echo "docker-buildx: GitHub API lookup failed (empty asset URL); retry online" >&2; exit 1; }; \
	mkdir -p $(@D); \
	curl -fL "$$url" -o $@ || { rm -f $@; exit 1; }
	chmod a+x $@

##
## https://github.com/docker/mcp-gateway/releases
##
$(HOME)/.docker/cli-plugins/docker-mcp: OS = $(shell uname -s | tr '[A-Z]' '[a-z]')
ifeq ($(MACHINE),aarch64)
$(HOME)/.docker/cli-plugins/docker-mcp: ARCH = arm64
else ifeq ($(MACHINE),x86_64)
$(HOME)/.docker/cli-plugins/docker-mcp: ARCH = amd64
else
$(HOME)/.docker/cli-plugins/docker-mcp: ARCH = $(shell uname -p)
endif
$(HOME)/.docker/cli-plugins/docker-mcp:
	@url="$(call github-prerelease-asset-url,docker/mcp-gateway,docker-mcp-$(OS)-$(ARCH),.tar.gz)"; test -n "$$url" || { echo "docker-mcp: GitHub API lookup failed (empty asset URL); retry online" >&2; exit 1; }; \
	mkdir -p $(@D) $(DOTFILES_TMPDIR); \
	tmp="$(DOTFILES_TMPDIR)/docker-mcp-$(OS)-$(ARCH).tar.gz"; \
	curl -fL "$$url" -o "$$tmp" || { rm -f "$$tmp"; exit 1; }; \
	tar -xzf "$$tmp" -C $(@D) || { rm -f "$$tmp"; exit 1; }; \
	rm -f "$$tmp"

##
## https://github.com/kerl/kerl/releases
##
$(HOME)/.local/bin/kerl:
	curl -fL https://raw.githubusercontent.com/kerl/kerl/master/kerl -o $@ || { rm -f $@; exit 1; }
	chmod a+x $@

##
## https://github.com/erlang/rebar3/releases
##
$(HOME)/.local/bin/rebar3:
	@url="$(call github-asset-url,erlang/rebar3,rebar3,)"; test -n "$$url" || { echo "rebar3: GitHub API lookup failed (empty asset URL); retry online" >&2; exit 1; }; \
	curl -fL "$$url" -o $@ || { rm -f $@; exit 1; }
	chmod a+x $@

##
## https://github.com/tmux/tmux/releases
##
.INTERMEDIATE: $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION).tar.gz $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION)

# ubuntu: libevent-dev libutf8proc-dev bison
# macOS: libevent pkg-config
$(HOME)/.local/bin/tmux: $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION)
	@test -n "$(strip $(TMUX_VERSION))" || { echo "TMUX_VERSION is empty (GitHub API lookup failed); retry online or run make TMUX_VERSION=3.4 <target>" >&2; exit 1; }
	cd $< \
		&& autoreconf -f -i \
		&& ./configure \
			--enable-utf8proc \
			--prefix=$(HOME)/.local \
		&& $(MAKE) && $(MAKE) install
	rm -rf $<
	touch $@

$(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION): $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION).tar.gz
	tar -xzf $< -C $(@D)
	touch $@

$(DOTFILES_TMPDIR)/tmux-%.tar.gz:
	@url="$(call github-asset-url,tmux/tmux,tmux-$*,.tar.gz)"; test -n "$$url" || { echo "TMUX_VERSION is empty or GitHub API lookup failed; retry online or run make TMUX_VERSION=3.4 <target>" >&2; exit 1; }; \
	mkdir -p $(@D); \
	curl -fL "$$url" -o $@ || { rm -f $@; exit 1; }

# Empty-version fallback: '%' never matches the empty stem, so without this
# `make TMUX_VERSION= ...tmux` dies with a bare "No rule" instead of the reason.
$(DOTFILES_TMPDIR)/tmux-.tar.gz:
	@echo "TMUX_VERSION is empty (GitHub API lookup failed); retry online or run make TMUX_VERSION=3.4 <target>" >&2; exit 1

update/versioned: FORCE
	$(MAKE) clean/versioned
	$(MAKE) install/versioned

.PHONY: install/versioned clean/versioned update/versioned

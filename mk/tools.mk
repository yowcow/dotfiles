VERSIONED_TARGETS := \
		$(HOME)/.docker/cli-plugins/docker-buildx \
		$(HOME)/.docker/cli-plugins/docker-mcp \
		$(HOME)/.local/bin/aws-vault \
		$(HOME)/.local/bin/rebar3 \
		$(HOME)/.local/bin/kerl \
		$(HOME)/.local/bin/tmux \
		$(HOME)/.local/bin/zellij

install/versioned: $(VERSIONED_TARGETS)

clean/versioned: FORCE
	rm -f $(VERSIONED_TARGETS)

$(HOME)/.local/bin/buf.pl:
	mkdir -p $(@D)
	curl -fL https://raw.githubusercontent.com/yowcow/buf/main/bin/buf.pl -o $@ \
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
	curl -fL "$(call github-asset-url,ByteNess/aws-vault,aws-vault-$(OS)-$(ARCH),)" -o $@
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
	mkdir -p $(@D)
	curl -fL "$(call github-asset-url,docker/buildx,buildx-,.$(OS)-$(ARCH))" -o $@
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
	mkdir -p $(@D)
	curl -fL "$(call github-prerelease-asset-url,docker/mcp-gateway,docker-mcp-$(OS)-$(ARCH),.tar.gz)" | tar -xz -C $(@D)

##
## https://github.com/kerl/kerl/releases
##
$(HOME)/.local/bin/kerl:
	curl -fL https://raw.githubusercontent.com/kerl/kerl/master/kerl -o $@
	chmod a+x $@

##
## https://github.com/erlang/rebar3/releases
##
$(HOME)/.local/bin/rebar3:
	curl -fL "$(call github-asset-url,erlang/rebar3,rebar3,)" -o $@
	chmod a+x $@

##
## https://github.com/tmux/tmux/releases
##
.INTERMEDIATE: $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION).tar.gz $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION)

# ubuntu: libevent-dev libutf8proc-dev bison
# macOS: libevent pkg-config
$(HOME)/.local/bin/tmux: $(DOTFILES_TMPDIR)/tmux-$(TMUX_VERSION)
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
	mkdir -p $(@D)
	curl -fL "$(call github-asset-url,tmux/tmux,tmux-$*,.tar.gz)" -o $@

##
## https://github.com/zellij-org/zellij/releases
##
.INTERMEDIATE: $(DOTFILES_TMPDIR)/zellij.tar.gz

$(HOME)/.local/bin/zellij: $(DOTFILES_TMPDIR)/zellij.tar.gz
	tar -xzf $< -C $(@D)
	touch $@

ifeq ($(shell uname -s),Darwin)
$(DOTFILES_TMPDIR)/zellij.tar.gz: URL = $(call github-asset-url,zellij-org/zellij,zellij-$(MACHINE)-apple-darwin,.tar.gz)
else
$(DOTFILES_TMPDIR)/zellij.tar.gz: URL = $(call github-asset-url,zellij-org/zellij,zellij-$(MACHINE)-unknown-linux-musl,.tar.gz)
endif
$(DOTFILES_TMPDIR)/zellij.tar.gz:
	mkdir -p $(@D)
	curl -fL "$(URL)" -o $@

.PHONY: install/versioned clean/versioned

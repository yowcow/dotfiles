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

github-latest = $(shell curl -fsSL "https://api.github.com/repos/$(1)/releases" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\([^"]*\)".*/\1/')

AWS_VAULT_VERSION     ?= $(call github-latest,ByteNess/aws-vault)
DOCKER_BUILDX_VERSION ?= $(call github-latest,docker/buildx)
DOCKER_MCP_VERSION    ?= $(call github-latest,docker/mcp-gateway)
REBAR3_VERSION        ?= $(call github-latest,erlang/rebar3)
ZELLIJ_VERSION        ?= $(call github-latest,zellij-org/zellij)

ifndef TMUX_VERSION
TMUX_VERSION := $(call github-latest,tmux/tmux)
endif

include mk/tools.mk mk/modules.mk mk/update.mk

##
## Top-level targets
##
all:
	$(MAKE) install

install: $(TARGETS)
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

update:
	$(MAKE) $(addprefix update/,$(GIT_MODULES))
	$(MAKE) $(addprefix update/lang/,golang nodejs python3 rust)
	$(MAKE) update/docker
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

clean:
	rm -f $(TARGETS)

realclean: clean
	rm -rf _modules

##
## Symlink rules
##
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
## Default fallback
##
$(HOME)/.%: %
	mkdir -p $(@D)
	ln -sfn `pwd`/$* $@

FORCE:

.PHONY: all install update clean realclean

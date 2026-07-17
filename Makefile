DOTFILES_TMPDIR = /tmp/dotfiles-tmp

MACHINE := $(shell uname -m)
ifeq ($(MACHINE),arm64)
MACHINE = aarch64
endif

SOURCES := \
	config/alacritty/alacritty.toml \
	config/alacritty-theme \
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
	zshrc

# Shared AI assistant guidelines — one source file, multiple install targets.
# By default each target symlinks to the shared file; if an agent-specific overlay
# exists, Make concatenates the shared file and that overlay into the installed target.
AI_GUIDELINES      := ai/GUIDELINES.md
AI_CLAUDE_TARGET   := $(HOME)/.claude/CLAUDE.md
AI_GEMINI_TARGET   := $(HOME)/.gemini/GEMINI.md
AI_CODEX_TARGET    := $(HOME)/.codex/AGENTS.md
AI_TARGETS         := $(AI_CLAUDE_TARGET) $(AI_GEMINI_TARGET) $(AI_CODEX_TARGET)
AI_CLAUDE_OVERLAY ?= ai/agents/claude/CLAUDE.append.md
AI_GEMINI_OVERLAY ?= ai/agents/gemini/GEMINI.append.md
AI_CODEX_OVERLAY  ?= ai/agents/codex/AGENTS.append.md
AI_CLAUDE_DEPS     := $(AI_GUIDELINES) $(wildcard $(AI_CLAUDE_OVERLAY))
AI_GEMINI_DEPS     := $(AI_GUIDELINES) $(wildcard $(AI_GEMINI_OVERLAY))
AI_CODEX_DEPS      := $(AI_GUIDELINES) $(wildcard $(AI_CODEX_OVERLAY))
AI_GUIDELINES_ABS  := $(abspath $(AI_GUIDELINES))

# Shared AI assistant skills — one source directory, multiple symlink targets
AI_SKILLS_DIR    := ai/skills
AI_SKILL_NAMES   := simplify-code pr-to-ready investigate-performance investigate-anomaly
AI_SKILL_TARGETS := $(foreach skill,$(AI_SKILL_NAMES),$(HOME)/.claude/skills/$(skill) $(HOME)/.gemini/skills/$(skill) $(HOME)/.agents/skills/$(skill) $(HOME)/.codex/skills/$(skill))

# Shared AI assistant agents — prompts and custom agent definitions
AI_AGENTS_DIR                  := ai/agents
AI_AGENT_NAMES                 := simplify-code
AI_CODEX_AGENT_TARGETS         := $(foreach agent,$(AI_AGENT_NAMES),$(HOME)/.codex/agents/$(agent).toml)
AI_ANTIGRAVITY_AGENT_TARGETS   := $(foreach agent,$(AI_AGENT_NAMES),$(HOME)/.gemini/antigravity-cli/.agents/agents/$(subst -,_,$(agent))/agent.json)
AI_AGENT_TARGETS               := $(AI_CODEX_AGENT_TARGETS) $(AI_ANTIGRAVITY_AGENT_TARGETS)

TARGETS := $(addprefix $(HOME)/.,$(SOURCES)) $(AI_TARGETS) $(AI_SKILL_TARGETS) $(AI_AGENT_TARGETS)

ALACRITTY_THEME := _modules/github.com/alacritty/alacritty-theme
FZF             := _modules/github.com/junegunn/fzf
GOENV           := _modules/github.com/go-nv/goenv
NVM             := _modules/github.com/nvm-sh/nvm
PYENV           := _modules/github.com/pyenv/pyenv
WOFI_ARC        := _modules/github.com/sachahjkl/wofi-arc-dark

GIT_MODULES := $(ALACRITTY_THEME) \
			   $(FZF) \
			   $(GOENV) \
			   $(NVM) \
			   $(PYENV) \
			   $(WOFI_ARC)

ifeq ($(shell make -v | head -1 | rev | cut -d' ' -f1 | rev | cut -d'.' -f1),3)
MAKE := make -j4
else
MAKE := make -j4 -O
endif

# Latest non-prerelease tag of a repo (used where we need the version string itself).
github-latest = $(shell curl -fsSL "https://api.github.com/repos/$(1)/releases/latest" | jq -r '.tag_name')

# Resolve a release asset's real download URL straight from the GitHub API, instead of
# hand-building URLs that break when a project's tag/asset naming drifts.
#   $(1)=owner/repo  $(2)=asset-name prefix  $(3)=asset-name suffix
github-asset-url = $(shell curl -fsSL "https://api.github.com/repos/$(1)/releases/latest" | jq -r '[.assets[] | select((.name|startswith("$(2)")) and (.name|endswith("$(3)")))][0].browser_download_url')

# Same, but for repos that publish only pre-releases (no /releases/latest), e.g. docker/mcp-gateway.
github-prerelease-asset-url = $(shell curl -fsSL "https://api.github.com/repos/$(1)/releases" | jq -r '[.[0].assets[] | select((.name|startswith("$(2)")) and (.name|endswith("$(3)")))][0].browser_download_url')

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
	$(MAKE) install/versioned
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

update:
	$(MAKE) $(addprefix update/,$(GIT_MODULES))
	$(MAKE) $(addprefix update/lang/,golang nodejs python3 rust)
	$(MAKE) update/docker
	$(MAKE) update/codex
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

clean:
	rm -f $(TARGETS)

realclean: clean
	rm -rf _modules

##
## Symlink rules
##
$(AI_CLAUDE_TARGET): FORCE $(AI_CLAUDE_DEPS)
	mkdir -p $(@D)
	if [ -f "$(AI_CLAUDE_OVERLAY)" ]; then \
		rm -f $@; \
		cat $(AI_GUIDELINES_ABS) $(abspath $(AI_CLAUDE_OVERLAY)) > $@; \
	else \
		ln -sfn $(AI_GUIDELINES_ABS) $@; \
	fi

$(AI_GEMINI_TARGET): FORCE $(AI_GEMINI_DEPS)
	mkdir -p $(@D)
	if [ -f "$(AI_GEMINI_OVERLAY)" ]; then \
		rm -f $@; \
		cat $(AI_GUIDELINES_ABS) $(abspath $(AI_GEMINI_OVERLAY)) > $@; \
	else \
		ln -sfn $(AI_GUIDELINES_ABS) $@; \
	fi

$(AI_CODEX_TARGET): FORCE $(AI_CODEX_DEPS)
	mkdir -p $(@D)
	if [ -f "$(AI_CODEX_OVERLAY)" ]; then \
		rm -f $@; \
		cat $(AI_GUIDELINES_ABS) $(abspath $(AI_CODEX_OVERLAY)) > $@; \
	else \
		ln -sfn $(AI_GUIDELINES_ABS) $@; \
	fi

$(HOME)/.claude/skills/%: $(AI_SKILLS_DIR)/%
	mkdir -p $(@D)
	ln -sfn `pwd`/$< $@

$(HOME)/.gemini/skills/%: $(AI_SKILLS_DIR)/%
	mkdir -p $(@D)
	ln -sfn `pwd`/$< $@

$(HOME)/.agents/skills/%: $(AI_SKILLS_DIR)/%
	mkdir -p $(@D)
	ln -sfn `pwd`/$< $@

$(HOME)/.codex/skills/%: $(AI_SKILLS_DIR)/%
	mkdir -p $(@D)
	ln -sfn `pwd`/$< $@

$(HOME)/.codex/agents/%.toml: $(AI_AGENTS_DIR)/%/codex.toml
	mkdir -p $(@D)
	ln -sfn `pwd`/$< $@

$(HOME)/.gemini/antigravity-cli/.agents/agents/simplify_code/agent.json: $(AI_AGENTS_DIR)/simplify-code/antigravity/agent.json
	mkdir -p $(@D)
	ln -sfn `pwd`/$< $@

$(HOME)/.config/alacritty-theme: $(ALACRITTY_THEME)
	mkdir -p $(@D)
	ln -sfn `pwd`/$< $@

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

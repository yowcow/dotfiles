ZPREZTO_SOURCES := zlogin zlogout zshenv
SOURCES := \
	Xmodmap \
	Xresources \
	config/alacritty/alacritty.yml \
	config/i3/config \
	config/i3blocks/config \
	config/kanshi/config \
	config/nvim/after/indent/php.vim \
	config/nvim/init.lua \
	config/sql-formatter/config.json \
	config/sway/config \
	config/sway/background.jpg \
	config/waybar/config \
	config/waybar/style.css \
	config/wezterm/wezterm.lua \
	config/wofi/style.css \
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
	local/share/nvim/site/pack/paqs/start/paq-nvim \
	nodenv \
	nodenv.zsh \
	nodenv/plugins/node-build \
	npmrc \
	ocamlinit \
	p10k.zsh \
	tmux.conf \
	xprofile \
	zprezto \
	zpreztorc \
	zshrc \
	$(ZPREZTO_SOURCES)

TARGETS := $(addprefix $(HOME)/.,$(SOURCES))

ERLANG_LS    := _modules/github.com/erlang-ls/erlang_ls
FZF          := _modules/github.com/junegunn/fzf
GOENV        := _modules/github.com/syndbg/goenv
I3BLOCKS     := _modules/github.com/vivien/i3blocks-contrib
NODENV       := _modules/github.com/nodenv/nodenv
NODENV_BUILD := _modules/github.com/nodenv/node-build
PAQ_NVIM     := _modules/github.com/savq/paq-nvim
PREZTO       := _modules/github.com/sorin-ionescu/prezto
WOFI_ARC     := _modules/github.com/sachahjkl/wofi-arc-dark

GIT_MODULES := $(ERLANG_LS) \
			   $(FZF) \
			   $(GOENV) \
			   $(I3BLOCKS) \
			   $(NODENV) \
			   $(NODENV_BUILD) \
			   $(PAQ_NVIM) \
			   $(PREZTO) \
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

$(HOME)/.config/%.jpg: config/%.jpg.gpg
	gpg --decrypt -o $@ $<

$(HOME)/.config/i3blocks/config: $(I3BLOCKS)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/config/i3blocks/config $@

$(HOME)/.config/wofi/style.css: $(WOFI_ARC)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$</style.css $@

$(HOME)/.fzf: $(FZF)
	ln -sfn `pwd`/$< $@

$(HOME)/.goenv: $(GOENV)
	ln -sfn `pwd`/$< $@

$(HOME)/.local/bin/buf:
	mkdir -p $(dir $@)
	curl -L https://raw.githubusercontent.com/yowcow/buf/main/bin/buf.pl -o $@ \
		&& chmod +x $@

$(HOME)/.local/bin/erlang_ls: $(ERLANG_LS) FORCE
	mkdir -p $(dir $@)
	if which rebar3 1>/dev/null; then \
		$(MAKE) -C $< && \
		cp $</_build/default/bin/erlang_ls $@; \
	fi

$(HOME)/.local/share/nvim/site/pack/paqs/start/paq-nvim: $(PAQ_NVIM)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$</ $@

$(HOME)/.nodenv: $(NODENV)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

$(HOME)/.nodenv/plugins/node-build: $(NODENV_BUILD)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@

$(HOME)/.npmrc:
	echo 'prefix = $${HOME}/.npm' > $@

$(HOME)/.zprezto: $(PREZTO)
	ln -sfn `pwd`/$< $@

$(addprefix $(HOME)/.,$(ZPREZTO_SOURCES)): $(PREZTO)
	ln -sfn `pwd`/$</runcoms/$(subst .,,$(notdir $@)) $@

$(HOME)/.config/alacritty/alacritty.yml: ALACRITTY_FONT_SIZE := 9.0
ifeq ($(shell uname),Darwin)
$(HOME)/.config/alacritty/alacritty.yml: ALACRITTY_FONT_SIZE := 11.0
endif
$(HOME)/.config/alacritty/alacritty.yml: config/alacritty/alacritty.yml FORCE
	mkdir -p $(dir $@)
	cat $< \
		| sed 's/%%font_size%%/$(ALACRITTY_FONT_SIZE)/g' \
		> $@

ifeq ($(shell uname),Darwin)
$(HOME)/.gnupg/gpg-agent.conf: gnupg/gpg-agent.darwin.conf
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$< $@
endif

##
## Default Fallback
##
$(HOME)/.%: %
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$* $@

##
## Tasks
##
_modules/%:
	mkdir -p $(dir $@)
	git clone \
		--recurse-submodules \
		git@$$(echo $* | sed -e 's|/|:|') \
		$@

update:
	$(MAKE) $(addprefix update/,$(GIT_MODULES))
	$(MAKE) $(addprefix update/lang/,golang nodejs python3 python ruby rust)
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

update/_modules/%: FORCE $(HOME)/.gitconfig _modules/%
	git -C _modules/$* pull \
		&& git -C _modules/$* submodule sync --recursive \
		&& git -C _modules/$* submodule update --init --recursive

update/lang/golang: GOTOOLS := \
	golang.org/x/tools/cmd/goimports \
	golang.org/x/tools/gopls \
	honnef.co/go/tools/cmd/staticcheck
update/lang/golang: FORCE
	if which go 1>/dev/null; then \
		for mod in $(GOTOOLS); do \
			go install $$mod@latest; \
			echo "installed: $$mod"; \
		done \
	fi

update/lang/nodejs: FORCE
	if which npm 1>/dev/null; then \
		npm -g install \
			@ansible/ansible-language-server \
			@elm-tooling/elm-language-server \
			aws-cdk \
			elm \
			elm-format \
			elm-test \
			eslint \
			intelephense \
			neovim \
			npm \
			npm-check-updates \
			sql-formatter \
			sql-formatter-cli \
			tree-sitter-cli \
			typescript \
			typescript-language-server \
			vscode-langservers-extracted \
			yarn \
			; \
	fi

update/lang/python3: FORCE
	if which pip3 1>/dev/null; then \
		pip3 install --upgrade \
			pynvim \
			msgpack \
			sqlparse \
			yq \
			; \
	fi

update/lang/python: FORCE
	if which pip 1>/dev/null; then \
		pip install --upgrade \
			neovim \
			pynvim \
			msgpack \
			; \
	fi

update/lang/ruby: FORCE
	## WTF?? Do:
	## travis login --com --github-token XXXX
	if which gem 1>/dev/null; then \
		gem install --user-install --no-document \
			travis \
			neovim; \
	fi

update/lang/rust: FORCE
	(which rustup && rustup update) || true

clean:
	rm -f $(TARGETS)

realclean: clean
	rm -rf _modules

FORCE:

.PHONY: all install update clean realclean

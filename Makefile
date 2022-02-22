ZPREZTO_SOURCES := zlogin zlogout zshenv
SOURCES := \
	Xmodmap \
	Xresources \
	config/alacritty/alacritty.yml \
	config/i3/config \
	config/i3blocks/config \
	config/kanshi/config \
	config/nvim/after \
	config/nvim/init.lua \
	config/sway/config \
	config/waybar/config \
	config/waybar/style.css \
	config/wofi/style.css \
	fzf \
	gitconfig \
	gitignore_global \
	gnupg/gpg-agent.conf \
	gnupg/gpg.conf \
	goenv \
	goenv.zsh \
	local/bin/buf \
	local/bin/erlang_ls \
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

GIT_MODULES := $(ERLANG_LS) \
			   $(FZF) \
			   $(GOENV) \
			   $(I3BLOCKS) \
			   $(NODENV) \
			   $(NODENV_BUILD) \
			   $(PAQ_NVIM) \
			   $(PREZTO)

all:
	$(MAKE) install

install: $(TARGETS)
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

$(HOME)/.config/i3blocks/config: $(I3BLOCKS)
	mkdir -p $(dir $@)
	ln -sfn `pwd`/config/i3blocks/config $@

$(HOME)/.fzf: $(FZF)
	ln -sfn `pwd`/$< $@

$(HOME)/.goenv: $(GOENV)
	ln -sfn `pwd`/$< $@

$(HOME)/.local/bin/buf:
	mkdir -p $(dir $@)
	curl -L https://raw.githubusercontent.com/yowcow/buf/main/bin/buf.pl -o $@ \
		&& chmod +x $@

$(HOME)/.local/bin/erlang_ls: $(ERLANG_LS)
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

$(HOME)/.%: %
	mkdir -p $(dir $@)
	ln -sfn `pwd`/$* $@

_modules/%:
	mkdir -p $(dir $@)
	git clone \
		--depth=1 \
		--recurse-submodules \
		git@$$(echo $* | sed -e 's|/|:|') \
		$@

update:
	$(MAKE) $(addprefix update/,$(GIT_MODULES))
	$(MAKE) -j4 $(addprefix update/lang/,golang nodejs python3 python ruby)
	$(HOME)/.fzf/install --no-bash --no-fish --completion --key-bindings --update-rc

update/_modules/%: FORCE $(HOME)/.gitconfig _modules/%
	git -C _modules/$* pull --depth=1 \
		&& git -C _modules/$* submodule sync --recursive \
		&& git -C _modules/$* submodule update --depth=1 --init --recursive

update/lang/golang: GOTOOLS := \
	golang.org/x/tools/cmd/goimports \
	golang.org/x/tools/gopls \
	honnef.co/go/tools/cmd/staticcheck
update/lang/golang: FORCE
	@if which go 1>/dev/null; then \
		for mod in $(GOTOOLS); do \
			go install $$mod@latest; \
			echo "installed: $$mod"; \
		done \
	fi

update/lang/nodejs: FORCE
	@if which npm 1>/dev/null; then \
		npm -g install \
			@ansible/ansible-language-server \
			@elm-tooling/elm-language-server \
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
	@if which pip3 1>/dev/null; then \
		pip3 install --upgrade \
			pynvim \
			msgpack \
			sqlparse \
			yq \
			; \
	fi

update/lang/python: FORCE
	@if which pip 1>/dev/null; then \
		pip install --upgrade \
			neovim \
			pynvim \
			msgpack \
			; \
	fi

update/lang/ruby: FORCE
	## WTF?? Do:
	## travis login --com --github-token XXXX
	@if which gem 1>/dev/null; then \
		gem install --user-install --no-document \
			travis \
			neovim; \
	fi

clean:
	rm -f $(TARGETS)

realclean: clean
	rm -rf _modules

FORCE:

.PHONY: all install update clean realclean

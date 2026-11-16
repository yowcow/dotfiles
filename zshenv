# Read by every zsh, before /etc/zsh/zshrc. Keep it cheap and silent.

# Ubuntu's /etc/zsh/zshrc runs compinit unless this is set; zshrc runs its own
# after fpath is complete, so the global one only rewrites ~/.zcompdump.
skip_global_compinit=1

# Static defaults, so non-interactive shells see them too. ${X:-default} keeps
# any value the caller already passed.
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"
export PAGER="${PAGER:-less}"
export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-$HOME/.ripgreprc}"
export CARGO_NET_GIT_FETCH_WITH_CLI="${CARGO_NET_GIT_FETCH_WITH_CLI:-true}"
export AWS_REGION="${AWS_REGION:-ap-northeast-1}"
export AWS_VAULT_BACKEND="${AWS_VAULT_BACKEND:-pass}"
export AWS_VAULT_PASS_PREFIX="${AWS_VAULT_PASS_PREFIX:-aws-vault}"
export AWS_SESSION_TOKEN_TTL="${AWS_SESSION_TOKEN_TTL:-12h}"
export AWS_ASSUME_ROLE_TTL="${AWS_ASSUME_ROLE_TTL:-12h}"
export AWS_FEDERATION_TOKEN_TTL="${AWS_FEDERATION_TOKEN_TTL:-12h}"
export GOENV_ROOT="${GOENV_ROOT:-$HOME/.goenv}"
export GOPATH="${GOPATH:-$HOME/go}"
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"

# PATH is a set: a later duplicate is dropped, the first position wins.
typeset -U path

# Put the static PATH entries in front, in this order.
#   (no argument) add only the entries not in $path yet, so an order set up by
#                 the caller (venv, direnv, ...) is left as it is
#   --move        move every entry to the front, e.g. after macOS path_helper
#                 reordered PATH
function _dotfiles_path_prepend() {
    emulate -L zsh
    local -a dirs=(
        $HOME/.grok/bin(N/)
        $PYENV_ROOT/shims
        $PYENV_ROOT/bin
        $PNPM_HOME/bin
        $HOME/.nvm/current/bin
        $GOENV_ROOT/bin
        $GOENV_ROOT/shims
        $HOME/go/bin
        $HOME/.rye/shims
        /opt/homebrew/opt/coreutils/libexec/gnubin(N/)
        $HOME/.cargo/bin
        $HOME/.local/bin
        /usr/local/sbin
        /usr/local/bin
        /usr/sbin
        /usr/lib/cargo/bin
    )
    if [[ $1 == --move ]]; then
        path=($dirs $path)
    else
        # A parent that ran `nvm use` already put its node version on PATH.
        if [[ -n $NVM_BIN ]] && (( ${path[(Ie)$NVM_BIN]} )); then
            dirs=(${dirs:#$HOME/.nvm/current/bin})
        fi
        path=(${dirs:|path} $path)
    fi
}
_dotfiles_path_prepend

# Read by every zsh, before /etc/zsh/zshrc. Keep it cheap and silent.

# Ubuntu's /etc/zsh/zshrc runs compinit unless this is set; zshrc runs its own
# after fpath is complete, so the global one only rewrites ~/.zcompdump.
skip_global_compinit=1

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Static defaults, so non-interactive shells see them too. ${X:-default} keeps
# any value the caller already passed.
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"
export PAGER="${PAGER:-less}"
export LANG="${LANG:-en_US.UTF-8}"
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

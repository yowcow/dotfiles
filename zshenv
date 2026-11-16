# Read by every zsh, before /etc/zsh/zshrc. Keep it cheap and silent.

# Ubuntu's /etc/zsh/zshrc runs compinit unless this is set; zshrc runs its own
# after fpath is complete, so the global one only rewrites ~/.zcompdump.
skip_global_compinit=1

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

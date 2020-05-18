bindkey -v

autoload -Uz compinit vcs_info add-zsh-hook
compinit
setopt PROMPT_SUBST

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '%F{002}!!%f'
zstyle ':vcs_info:git:*' unstagedstr '%F{203}??%f'
zstyle ':vcs_info:*' formats 'on %%B%%F{003}%b%u%c%%f%%b'
zstyle ':vcs_info:*' actionformats 'on %%B%%F{001}%a%%f %%F{203}%b%u%c%%f%%b'

# https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
# orange: 203, 210
PROMPT='%B%F{002}%n%f at %F{203}%m%f in %F{006}%~%f ${vcs_info_msg_0_}%b
%B~>%b> '

add-zsh-hook precmd vcs_info # hook vcs_info

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

HISTFILE=~/.zsh_histfile
HISTSIZE=1000000
SAVEHIST=1000000

setopt hist_ignore_dups
setopt share_history
setopt magic_equal_subst

alias vi="nvim"
alias be="bundle exec"
alias ce="carton exec"
alias realpath="readlink"

export EDITOR=nvim
export PAGER=less
export LANG="en_US.UTF-8"

export PATH=$HOME/bin:$HOME/.fzf/bin:$HOME/.npm/bin:$HOME/go/bin:/usr/local/sbin:/usr/sbin:$PATH

export GOPATH=$HOME/go
export GOPRIVATE=github.com/voyagegroup

case "${OSTYPE}" in
    darwin*)
        alias ls="ls -G"
        alias zcat="gunzip -c"
        ;;
    linux*)
        alias ls="ls --color"
        # ssh-agent
        if [ "$(pgrep ssh-agent | wc -l)" = "0" ]; then
            eval $(ssh-agent);
            ln -fs $SSH_AUTH_SOCK /tmp/ssh-auth.sock;
            ssh-agent $HOME/.ssh/id_rsa;
        else
            export SSH_AGENT_PID=$(pgrep ssh-agent | head -n1)
        fi
        export SSH_AUTH_SOCK=/tmp/ssh-auth.sock
        ;;
esac

# functions
aws-link() {
    case "$1" in
        "status")
            readlink ~/.aws
            ;;
        "update")
            [ -d ~/.aws.$2 ] && \
            rm -f ~/.aws && \
            ln -s ~/.aws.$2 ~/.aws && \
            echo "Linked AWS config to '~/.aws.$2'!"
            ;;
        *)
            echo "Usage: $0 [status] [update <name>]"
    esac
}

umask 022

# .ssh/config to have `HashKnownHosts no` will help
_cache_hosts=($([ -f ~/.ssh/known_hosts ] && cat ~/.ssh/known_hosts | cut -d',' -f1))

# general ***env
[ -f $HOME/.nodenv.zsh ] && source ~/.nodenv.zsh
[ -f $HOME/.goenv.zsh ] && source ~/.goenv.zsh
[ -f $HOME/.fzf.zsh ] && source ~/.fzf.zsh
[ -f $HOME/.travis/travis.sh ] && source ~/.travis/travis.sh
[ -f $HOME/.zshlocal ] && source ~/.zshlocal

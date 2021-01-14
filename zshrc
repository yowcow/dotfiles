bindkey -v

autoload -Uz compinit vcs_info add-zsh-hook
compinit
setopt PROMPT_SUBST

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '%F{118}!!%f'
zstyle ':vcs_info:git:*' unstagedstr '%F{210}??%f'
zstyle ':vcs_info:*' formats '» %%B%%F{193}%b%u%c%%f%%b'
zstyle ':vcs_info:*' actionformats '» %%B%%F{229}%%K{161} %a %%k%f %%F{229}%b%u%c%%f%%b'

# https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
# red: 166
# pink: 161
# yellow: 229
# orange: 208
# bright orange: 222
# magenta: 135
# pistachio: 193
# cyan: 81
# blue: 75
PROMPT='%F{208}%B%n@%U%m%u%b%f » %F{81}%B%~%b%f ${vcs_info_msg_0_}
%B»%b '

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

export PATH=$HOME/.fzf/bin:$HOME/.npm/bin:$HOME/.local/bin:$HOME/go/bin:/usr/local/sbin:/usr/sbin:$PATH

export GOPATH=$HOME/go
export GOPRIVATE=github.com/voyagegroup

umask 022

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

cert-check() {
    echo \
        | openssl s_client -showcerts -servername $1 -connect $1:${2:-443} 2>/dev/null \
        | openssl x509 -inform pem -noout -text
}

ssh-agent-start() {
    if [ ! -z "$(which ssh-agent)" ]; then
        if [ -z "$(pgrep -U $(whoami) ssh-agent)" ]; then
            eval $(ssh-agent) && \
                ln -nsf $SSH_AUTH_SOCK /tmp/ssh-auth.sock && \
                export SSH_AUTH_SOCK=/tmp/ssh-auth.sock;
        else
            # some environment ssh-agent starts automatically
            [ -z $SSH_AGENT_PID ] && \
                export SSH_AGENT_PID=$(pgrep ssh-agent | head -n1);
            [ -L /tmp/ssh-auth.sock ] && \
                export SSH_AUTH_SOCK=/tmp/ssh-auth.sock;
        fi
        KEY=$HOME/.ssh/id_rsa \
            && [ -f $KEY ] \
            && [ -z "$(ssh-add -l | grep "${KEY}\b")" ] \
            && ssh-add $KEY;
    fi
}

ssh-agent-stop() {
    if [ ! -z "$(which ssh-agent)" ]; then
        if [ ! -z "$(pgrep -U $(whoami) ssh-agent)" ]; then
            pgrep -U $(whoami) ssh-agent | xargs kill -HUP;
            unset SSH_AGENT_PID;
            unset SSH_AUTH_SOCK;
        fi
    fi
}

ssh-agent-start

case "${OSTYPE}" in
    darwin*)
        alias ls="ls -G"
        alias zcat="gunzip -c"
        ;;
    linux*)
        alias ls="ls --color"
        ;;
esac

# .ssh/config to have `HashKnownHosts no` will help
_cache_hosts=($([ -f ~/.ssh/known_hosts ] && cat ~/.ssh/known_hosts | cut -d',' -f1))

# general ***env
[ -f $HOME/.plenv.zsh ] && source ~/.plenv.zsh
[ -f $HOME/.nodenv.zsh ] && source ~/.nodenv.zsh
[ -f $HOME/.goenv.zsh ] && source ~/.goenv.zsh
[ -f $HOME/.fzf.zsh ] && source ~/.fzf.zsh
[ -f $HOME/.travis/travis.sh ] && source ~/.travis/travis.sh
[ -f $HOME/.zshlocal ] && source ~/.zshlocal

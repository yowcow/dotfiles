# Declare this before p10k initialization
# https://unix.stackexchange.com/questions/608842/zshrc-export-gpg-tty-tty-says-not-a-tty
export GPG_TTY=$(tty)

alias vi="nvim"
alias vim="nvim"
alias realpath="readlink"
alias bt="bluetoothctl"
alias cal="ncal -b"

case "$(uname -s)" in
    "Darwin")
        alias ls="ls -G"
        alias zcat="gunzip -c"
        ;;
    "Linux")
        alias ls="ls --color"
        alias diff="diff --color"
        ;;
esac

ssh-agent-start() {
    if [ ! -z "$(which ssh-agent)" ]; then
        if [ -z "$(pgrep -U $(whoami) ssh-agent)" ]; then
            # update/create symlink so that I can find the path easily later on
            eval $(ssh-agent) && \
                ln -nsf $SSH_AUTH_SOCK /tmp/ssh-auth.sock
        else
            # some environment ssh-agent starts automatically
            [ -z $SSH_AGENT_PID ] && \
                export SSH_AGENT_PID=$(pgrep ssh-agent | head -n1);
            # find the path to sock and and restore the env
            [ -L /tmp/ssh-auth.sock ] && \
                export SSH_AUTH_SOCK=$(realpath /tmp/ssh-auth.sock);
        fi
        # add a key if its fingerprint is not in the agent
        KEY=$HOME/.ssh/id_rsa \
            && [ -f $KEY ] \
            && [ -z "$(ssh-add -l | grep $(ssh-keygen -lf $KEY | cut -d' ' -f2))" ] \
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

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

bindkey -v

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

export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LANG="en_US.UTF-8"
export PATH=$HOME/.fzf/bin:$HOME/.local/bin:$HOME/go/bin:/opt/julia/bin:/usr/local/sbin:/usr/sbin:$PATH

if which ruby >/dev/null && which gem >/dev/null; then
    PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
fi

export GOPATH=$HOME/go
export GOPRIVATE=github.com/voyagegroup

export AWS_REGION=ap-northeast-1
export AWS_VAULT_BACKEND=pass
export AWS_VAULT_PASS_PREFIX=aws-vault
export AWS_SESSION_TOKEN_TTL=6h
export AWS_ASSUME_ROLE_TTL=6h
export AWS_FEDERATION_TOKEN_TTL=6h

umask 022

colorlist() {
    for color in {000..015}; do
        print -nP "%F{$color}$color %f"
    done
    printf "\n"
    for color in {016..255}; do
        print -nP "%F{$color}$color %f"
        if [ $(($((color-16))%6)) -eq 5 ]; then
            printf "\n"
        fi
    done
}

aws-ec2() {
    if [ "$AWS_PROFILE" = "" ]; then
        echo '$AWS_PROFILE is required';
        return;
    fi
    aws-vault exec $AWS_PROFILE -- \
        aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=$1" "Name=instance-state-name,Values=running" \
            --query "Reservations[].Instances[]" \
            | jq '.[] | [
                .PrivateIpAddress,
                .PublicIpAddress,
                .InstanceId,
                .LaunchTime,
                (.Tags | map(select(.Key | test("^[A-Z]")) | [.Key, .Value] | join(":")) | join(","))
            ] | @tsv' -r
}

ssh-proxy() {
    if [ "$SSH_PROXY_HOST" = "" ]; then
        echo '$SSH_PROXY_HOST is required';
        return;
    fi
    if [ "$SSH_REMOTE_USER" = "" ]; then
        echo '$SSH_REMOTE_USER is required';
        return;
    fi
    SSH_PROXY_OPTIONS=(
        -o ProxyCommand="ssh -W %h:%p $SSH_PROXY_HOST"
        -o StrictHostKeyChecking=no
        -o UserKnownHostsFile=/dev/null
        -o TCPKeepAlive=yes
    );
    ssh-copy-id "${SSH_PROXY_OPTIONS[@]}" $SSH_REMOTE_USER@$1 2>/dev/null;
    ssh "${SSH_PROXY_OPTIONS[@]}" -t -t $SSH_REMOTE_USER@$1 $2;
}

cert-check() {
    echo \
        | openssl s_client -showcerts -servername $1 -connect $1:${2:-443} 2>/dev/null \
        | openssl x509 -inform pem -noout -text
}

# .ssh/config to have `HashKnownHosts no` will help
_cache_hosts=($([ -f ~/.ssh/known_hosts ] && cat ~/.ssh/known_hosts | cut -d',' -f1))

[ -f $HOME/.fzf.zsh ] && source ~/.fzf.zsh
[ -f $HOME/.goenv.zsh ] && source ~/.goenv.zsh
[ -f $HOME/.nodenv.zsh ] && source ~/.nodenv.zsh
[ -f $HOME/.p10k.zsh ] && source ~/.p10k.zsh
[ -f $HOME/.travis/travis.sh ] && source ~/.travis/travis.sh
[ -f $HOME/.zshlocal ] && source ~/.zshlocal

autoload -U +X bashcompinit && bashcompinit
[ -f /usr/bin/terraform ] && complete -o nospace -C /usr/bin/terraform terraform

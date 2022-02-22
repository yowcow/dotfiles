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

alias vi="nvim"
alias realpath="readlink"
alias bt="bluetoothctl"

export EDITOR=nvim
export PAGER=less
export LANG="en_US.UTF-8"
export GPG_TTY=$(tty)
export PATH=$HOME/.fzf/bin:$HOME/.local/bin:$HOME/go/bin:/opt/julia/bin:/usr/local/sbin:/usr/sbin:$PATH

for p in $(find $HOME/.gem/ruby -type d -name bin); do
    PATH=$p:$PATH;
done

export GOPATH=$HOME/go
export GOPRIVATE=github.com/voyagegroup

export AWS_REGION=ap-northeast-1
export AWS_VAULT_BACKEND=pass
export AWS_VAULT_PASS_PREFIX=aws-vault
export AWS_SESSION_TOKEN_TTL=1h

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
[ -f $HOME/.nodenv.zsh ] && source ~/.nodenv.zsh
[ -f $HOME/.goenv.zsh ] && source ~/.goenv.zsh
[ -f $HOME/.fzf.zsh ] && source ~/.fzf.zsh
[ -f $HOME/.travis/travis.sh ] && source ~/.travis/travis.sh
[ -f $HOME/.zshlocal ] && source ~/.zshlocal

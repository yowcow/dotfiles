umask 022
bindkey -v

# https://unix.stackexchange.com/questions/608842/zshrc-export-gpg-tty-tty-says-not-a-tty
export GPG_TTY=$(tty)

alias vi="nvim"
alias vim="nvim"
alias less="less -R"
alias realpath="readlink"
alias bt="bluetoothctl"
alias cal="ncal -C"
alias help="run-help"

case "$(uname -s)" in
    "Darwin")
        if [ -f "$(which gls)" ]; then
            alias ls="gls --color";
        else
            alias ls="ls -G";
        fi
        alias zcat="gunzip -c"
        ;;
    "Linux")
        alias ls="ls --color"
        alias diff="diff --color"
        ;;
esac

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

HISTFILE=~/.zsh_histfile
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt HIST_FIND_NO_DUPS
setopt share_history
setopt magic_equal_subst

export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LC_ALL=en_US.UTF-8
export LANG="en_US.UTF-8"
export PATH=$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/lib/cargo/bin:$PATH
export RIPGREP_CONFIG_PATH=$HOME/.ripgreprc

# .ssh/config to have `HashKnownHosts no` will help
# Load up to 200 hosts for SSH tab-completion in a single awk pass
[[ -f ~/.ssh/known_hosts ]] && \
    _cache_hosts=("${(f)$(awk -F'[, ]' 'NR<=200{print $1}' ~/.ssh/known_hosts)}")

# FZF specifically look for this line, so leaving it as it is
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export CARGO_NET_GIT_FETCH_WITH_CLI=true

# brew install coreutils
GNUBIN=/opt/homebrew/opt/coreutils/libexec/gnubin
if [ -d $GNUBIN ]; then
    PATH=$GNUBIN:$PATH;
fi

autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit
[ -f /usr/bin/terraform ] && complete -o nospace -C /usr/bin/terraform terraform

# start starship if available
which starship 1>/dev/null && eval "$(starship init zsh)"

# enable direnv if available
which direnv 1>/dev/null && eval "$(direnv hook zsh)"

export AWS_REGION=ap-northeast-1
export AWS_VAULT_BACKEND=pass
export AWS_VAULT_PASS_PREFIX=aws-vault
export AWS_SESSION_TOKEN_TTL=12h
export AWS_ASSUME_ROLE_TTL=12h
export AWS_FEDERATION_TOKEN_TTL=12h

#export CLAUDE_CODE_DISABLE_MOUSE=1
export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1
#export CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1

export ANTHROPIC_MODEL=fable
export CLAUDE_CODE_SUBAGENT_MODEL=sonnet
export CLAUDE_CODE_EFFORT_LEVEL=auto

function colorlist() {
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

function aws-ec2() {
    if [ "$AWS_PROFILE" = "" ]; then
        echo '$AWS_PROFILE is required';
        return;
    fi
    aws-vault exec $AWS_PROFILE -- \
        aws ec2 describe-instances \
            --output=json \
            --filters "Name=tag:Name,Values=$1" "Name=instance-state-name,Values=running" \
            --query "Reservations[].Instances[] | sort_by(@, &LaunchTime)" \
            | jq '.[] | [
                .InstanceId,
                .PrivateIpAddress,
                .PublicIpAddress,
                .LaunchTime,
                .State.Name,
                (.Tags | map(select(.Key | test("^[A-Z]")) | [.Key, .Value] | join(":")) | join(","))
            ] | @tsv' -r
}

function aws-session() {
    if [ "$AWS_PROFILE" = "" ]
    then
        echo '$AWS_PROFILE is required'
        return
    fi

    aws-vault exec $AWS_PROFILE -- \
        aws ssm start-session --target $1
}

function aws-exec () {
    if [ "$AWS_PROFILE" = "" ]
    then
        echo '$AWS_PROFILE is required'
        return
    fi

    # 引数チェック: インスタンスIDと実行コマンドが必要
    if [ $# -lt 2 ]; then
        echo "Usage: aws-exec <instance-id> <command>"
        echo "Example: aws-exec i-xxxxxx 'vmstat 1 5'"
        return
    fi

    local target=$1
    shift
    local cmd="$*"

    # SSMの非対話実行（AWS-StartInteractiveCommand）を利用
    aws-vault exec $AWS_PROFILE -- aws ssm start-session \
        --target "$target" \
        --document-name AWS-StartInteractiveCommand \
        --parameters "command=[\"$cmd\"]"
}

function ssh-proxy() {
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
    ssh "${SSH_PROXY_OPTIONS[@]}" -t -t $SSH_REMOTE_USER@$1;
}

function cert-check() {
    echo \
        | openssl s_client -showcerts -servername $1 -connect $1:${2:-443} 2>/dev/null \
        | openssl x509 -inform pem -noout -text
}

function git-url() {
    git remote get-url $1 \
        | sed 's/^.*@//; s/:/\//; s/\.git$//' \
        | while read -r url; do echo "https://${url}/commit/${2}"; done
}

# Remove local branches already merged into the current HEAD branch, and any
# clean linked worktrees checking them out. Local state only — no fetch, no
# remotes. Intended after you have updated the integration branch yourself
# (e.g. git pull). Squash-merged branches are not detected.
#
# Usage: git-branch-clean [--apply|-y] [--dry-run|-n]
#   Default is dry-run; pass --apply to actually delete.
#   Run while checked out on the integration branch (master/main/…).
function git-branch-clean() {
  local apply=0
  local arg
  for arg in "$@"; do
    case "$arg" in
      --apply|-y) apply=1 ;;
      --dry-run|-n) apply=0 ;;
      -h|--help)
        cat <<'EOF'
Usage: git-branch-clean [--apply|-y] [--dry-run|-n]

Remove local branches merged into the currently checked-out branch, and
their clean linked worktrees. Uses local repository state only (no fetch,
no remotes). Does not detect squash merges.

Run on the integration branch after you have updated it (e.g. git pull).
Default is dry-run; pass --apply to delete.
EOF
        return 0
        ;;
      *)
        echo "Unknown option: $arg" >&2
        return 1
        ;;
    esac
  done

  local main_wt
  main_wt="$(git rev-parse --show-toplevel)" || return 1

  local base_branch
  if ! base_branch="$(git symbolic-ref -q --short HEAD)"; then
    echo "Error: detached HEAD; check out the integration branch first" >&2
    return 1
  fi
  echo "Base: $base_branch (current branch, local only)"

  # branch -> worktree path (linked only; skip locked / detached / main)
  local -A wt_for_branch
  local wt_path="" branch="" locked=0
  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        wt_path="${line#worktree }"
        branch=""
        locked=0
        ;;
      branch\ refs/heads/*)
        branch="${line#branch refs/heads/}"
        ;;
      locked*)
        locked=1
        ;;
      "")
        if [[ -n "$wt_path" && -n "$branch" && "$locked" -eq 0 && "$wt_path" != "$main_wt" ]]; then
          wt_for_branch[$branch]="$wt_path"
        fi
        wt_path=""
        branch=""
        locked=0
        ;;
    esac
  done < <(git worktree list --porcelain)

  local merged_branch action_prefix
  if [[ "$apply" -eq 1 ]]; then
    action_prefix="Removing"
  else
    action_prefix="Would remove"
  fi

  while IFS= read -r merged_branch; do
    [[ -z "$merged_branch" ]] && continue
    # Never delete the branch we are on
    [[ "$merged_branch" == "$base_branch" ]] && continue

    # Linked worktree on this branch: require a clean tree before remove.
    # If it stays, the branch is still checked out and must not be deleted.
    local branch_held=0
    if [[ -n "${wt_for_branch[$merged_branch]:-}" ]]; then
      wt_path="${wt_for_branch[$merged_branch]}"
      local status_output
      if ! status_output="$(git -C "$wt_path" status --porcelain --ignore-submodules=none)"; then
        echo "Skip worktree (cannot read status): $wt_path ($merged_branch)"
        branch_held=1
      elif [[ -n "$status_output" ]]; then
        echo "Skip worktree (dirty): $wt_path ($merged_branch)"
        branch_held=1
      else
        echo "$action_prefix worktree: $wt_path ($merged_branch)"
        if [[ "$apply" -eq 1 ]]; then
          if ! git worktree remove --force --force "$wt_path"; then
            echo "Skip worktree (remove failed): $wt_path"
            branch_held=1
          fi
        fi
      fi
    fi

    # -d re-checks merged-into-HEAD; safe now that base is the local HEAD.
    if [[ "$branch_held" -eq 0 ]] && git show-ref --verify --quiet "refs/heads/${merged_branch}"; then
      echo "$action_prefix branch: $merged_branch"
      if [[ "$apply" -eq 1 ]]; then
        git branch -d "$merged_branch" || {
          echo "Skip branch (delete failed): $merged_branch"
        }
      fi
    fi
  done < <(git branch --merged HEAD --format='%(refname:short)')
}

function pin() {
    for pin in $(shuf --random-source=/dev/urandom -i0-9999 -n5); do printf '%04d\n' $pin; done
}

function lemonade-server-start() {
    if [ "$(pgrep lemonade)" = "" ]; then
        lemonade server &; disown;
        echo "Lemonade PID: $(pgrep lemonade)";
    fi
}

function ssh-agent-start() {
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
        for key in $HOME/.ssh/id_rsa $HOME/.ssh/id_ed25519; do \
            # add a key if its fingerprint is not in the agent
            [ -f $key ] \
            && [ -z "$(ssh-add -l | grep $(ssh-keygen -lf $key | cut -d' ' -f2))" ] \
            && ssh-add $key; \
        done;
    fi
}

function ssh-agent-stop() {
    if [ ! -z "$(which ssh-agent)" ]; then
        if [ ! -z "$(pgrep -U $(whoami) ssh-agent)" ]; then
            pgrep -U $(whoami) ssh-agent | xargs kill -HUP;
            unset SSH_AGENT_PID;
            unset SSH_AUTH_SOCK;
        fi
    fi
}

ssh-agent-start

for src in .cargo/env .rye/env .goenv.zsh .luarocks.zsh .nvm.zsh .pyenv.zsh .grok.zsh .local.zsh; do
    [ -f $HOME/$src ] && source $HOME/$src;
done

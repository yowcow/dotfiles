umask 022
bindkey -v

# https://unix.stackexchange.com/questions/608842/zshrc-export-gpg-tty-tty-says-not-a-tty
export GPG_TTY=$(tty)

alias vi="nvim"
alias vim="nvim"
alias less="less -R"
alias bt="bluetoothctl"
command -v ncal >/dev/null 2>&1 && alias cal="ncal -C"
alias help="run-help"

case "$(uname -s)" in
    "Darwin")
        _dotfiles_path_prepend --move
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

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# .ssh/config to have `HashKnownHosts no` will help
# Load up to 200 hosts for SSH tab-completion in a single awk pass
[[ -f ~/.ssh/known_hosts ]] && \
    _cache_hosts=("${(f)$(awk -F'[, ]' 'NR<=200{print $1}' ~/.ssh/known_hosts)}")

# FZF specifically look for this line, so leaving it as it is
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

for src in .goenv.zsh .luarocks.zsh .nvm.zsh .pyenv.zsh .ai-agents.zsh; do
    [ -f "$HOME/$src" ] && source "$HOME/$src"
done

autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit
[ -f /usr/bin/terraform ] && complete -o nospace -C /usr/bin/terraform terraform

# start starship if available
which starship 1>/dev/null && eval "$(starship init zsh)"

# enable direnv if available
which direnv 1>/dev/null && eval "$(direnv hook zsh)"

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
    # Policy (#279): ephemeral cloud targets rotate host keys, so prompts are
    # unworkable; accept-new keeps changed-key detection within this file's
    # lifetime instead of disabling checks entirely (StrictHostKeyChecking=no).
    # Reset with: rm ~/.ssh/known_hosts_ephemeral
    SSH_PROXY_OPTIONS=(
        -o ProxyCommand="ssh -W %h:%p $SSH_PROXY_HOST"
        -o StrictHostKeyChecking=accept-new
        -o UserKnownHostsFile=~/.ssh/known_hosts_ephemeral
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
    if [[ $# -ne 2 || -z "$1" || -z "$2" ]]; then
        echo "usage: git-url <remote> <commit>" >&2
        return 1
    fi
    local raw url
    raw=$(git remote get-url -- "$1") || return $?
    url=$(printf '%s\n' "$raw" | sed -e 's/\.git$//' -e 's|^ssh://[^@]*@|https://|' -e 's|^ssh://|https://|' -e 's/^git@\([^:]*\):/https:\/\/\1\//' -e 's|^http://|https://|' -e 's|^\(https://\)[^/]*@|\1|' -e 's|^\(https://[^/:]*\):[0-9][0-9]*/|\1/|')
    case "$url" in
        https://*) echo "${url}/commit/${2}" ;;
        *) echo "git-url: unsupported remote URL: $raw" >&2; return 1 ;;
    esac
}

# Remove local branches merged into the base branch (origin/HEAD by default),
# and their clean linked worktrees. Dry-run unless --force; see --help.
function git-branch-clean() {
  local apply=0 fetch=0 base=""
  while (( $# > 0 )); do
    case "$1" in
      --force|-f) apply=1 ;;
      --dry-run|-n) apply=0 ;;
      --fetch) fetch=1 ;;
      --base|--base=*)
        if [[ "$1" == --base=* ]]; then
          base="${1#--base=}"
        else
          shift
          base="${1:-}"
        fi
        if [[ -z "$base" ]]; then
          echo "Error: --base requires a branch name" >&2
          return 1
        fi
        ;;
      -h|--help)
        cat <<'EOF'
Usage: git-branch-clean [--force|-f] [--dry-run|-n] [--base <branch>] [--fetch]

Remove local branches merged into the base branch, and their clean linked
worktrees. The base defaults to the branch origin/HEAD points at; override it
with --base. It errors out when no base can be determined. The candidates
are the same from whichever branch or worktree you run it.

Never deleted: the base branch, and any branch checked out in a worktree
(the main checkout included) other than a clean linked worktree removed here.
The main checkout itself is never removed. Does not detect squash merges.

Without --fetch, uses local state only and judges against the local <base>.
With --fetch, runs git fetch --prune origin first and judges against
origin/<base>.

Default is dry-run; pass --force to delete.
EOF
        return 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        return 1
        ;;
    esac
    shift
  done

  if [[ -z "$base" ]]; then
    local origin_head
    if ! origin_head="$(git symbolic-ref -q refs/remotes/origin/HEAD)"; then
      echo "Error: origin/HEAD is not set; pass --base <branch>" >&2
      echo "       (or run: git remote set-head origin --auto)" >&2
      return 1
    fi
    base="${origin_head#refs/remotes/origin/}"
  fi

  local base_ref base_label
  if [[ "$fetch" -eq 1 ]]; then
    git fetch --prune origin || return 1
    base_ref="refs/remotes/origin/$base" base_label="origin/$base (fetched)"
  else
    base_ref="refs/heads/$base" base_label="$base (local only)"
  fi
  if ! git show-ref --verify --quiet "$base_ref"; then
    echo "Error: base ref not found: $base_ref" >&2
    return 1
  fi
  echo "Base: $base_label"

  # branch -> worktree path for every worktree. git lists the main checkout
  # first; its path is kept so it is never treated as a removable worktree.
  local -A wt_for_branch
  local main_wt="" wt_path="" line
  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        wt_path="${line#worktree }"
        [[ -z "$main_wt" ]] && main_wt="$wt_path"
        ;;
      branch\ refs/heads/*)
        wt_for_branch[${line#branch refs/heads/}]="$wt_path"
        ;;
    esac
  done < <(git worktree list --porcelain)

  # Mutating commands run against the main checkout: the current directory may
  # be a linked worktree that gets removed below. Resolve it now, while it
  # still exists: git reports worktree paths with symlinks resolved.
  local merged_branch action_prefix status_output branch_held cwd_removed=0
  local cwd="${PWD:A}"
  if [[ "$apply" -eq 1 ]]; then
    action_prefix="Removing"
  else
    action_prefix="Would remove"
  fi

  while IFS= read -r merged_branch; do
    [[ "$merged_branch" == "$base" ]] && continue

    # Checked out somewhere: only a clean linked worktree may be removed, and
    # only then is the branch free to delete.
    branch_held=0
    wt_path="${wt_for_branch[$merged_branch]:-}"
    if [[ -n "$wt_path" ]]; then
      if [[ "$wt_path" == "$main_wt" ]]; then
        echo "Skip branch (checked out in main checkout): $merged_branch"
        branch_held=1
      elif ! status_output="$(git -C "$wt_path" status --porcelain --ignore-submodules=none)"; then
        echo "Skip worktree (cannot read status): $wt_path ($merged_branch)"
        branch_held=1
      elif [[ -n "$status_output" ]]; then
        echo "Skip worktree (dirty): $wt_path ($merged_branch)"
        branch_held=1
      else
        echo "$action_prefix worktree: $wt_path ($merged_branch)"
        if [[ "$apply" -eq 1 ]]; then
          if ! git -C "$main_wt" worktree remove --force --force "$wt_path"; then
            echo "Skip worktree (remove failed): $wt_path"
            branch_held=1
          elif [[ "$cwd" == "$wt_path" || "$cwd" == "$wt_path"/* ]]; then
            cwd_removed=1
          fi
        fi
      fi
    fi

    # -D, not -d: -d checks HEAD/upstream, not the base. Merged-into-base was
    # already established by --merged above.
    if [[ "$branch_held" -eq 0 ]]; then
      echo "$action_prefix branch: $merged_branch"
      if [[ "$apply" -eq 1 ]]; then
        git -C "$main_wt" branch -D "$merged_branch" || {
          echo "Skip branch (delete failed): $merged_branch"
        }
      fi
    fi
  done < <(git for-each-ref --merged "$base_ref" --format='%(refname:lstrip=2)' refs/heads/)

  if [[ "$cwd_removed" -eq 1 ]]; then
    echo "Note: the current directory was removed; cd \"$main_wt\""
  fi
}

function pin() {
    for pin in $(shuf --random-source=/dev/urandom -i0-9999 -n5); do printf '%04d\n' $pin; done
}

function ssh-agent-start() {
    local _sock
    if [ ! -z "$(which ssh-agent)" ]; then
        if [ -z "$(pgrep -U $(whoami) ssh-agent)" ]; then
            # update/create symlink so that I can find the path easily later on
            eval $(ssh-agent) && \
                ln -nsf $SSH_AUTH_SOCK /tmp/ssh-auth.sock
        else
            # some environment ssh-agent starts automatically
            [ -z $SSH_AGENT_PID ] && \
                export SSH_AGENT_PID=$(pgrep -U $(whoami) ssh-agent | head -n1);
            # find the path to sock and and restore the env
            # /tmp/ssh-auth.sock is a symlink here ([ -L ] guard); absolutize
            # a relative target so SSH_AUTH_SOCK never ends up relative.
            # Anything that fails (dead link, or a socket/dir not owned by this
            # user) clears the var rather than leaving a stale export.
            # /tmp is shared: resolve fully and require our ownership so another
            # user can't swap the path after the check.
            if [ -L /tmp/ssh-auth.sock ]; then
                _sock=$(readlink /tmp/ssh-auth.sock) && \
                [ -n "$_sock" ] && \
                case "$_sock" in /*) ;; *) _sock="/tmp/$_sock";; esac && \
                _sock=${_sock:A} && \
                [ -S "$_sock" ] && [ -O "$_sock" ] && [ -O "${_sock:h}" ] && \
                export SSH_AUTH_SOCK="$_sock" || unset SSH_AUTH_SOCK;
            fi; unset _sock;
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

function gpg-reload() {
    # drop cached passphrases, then sign a dummy message to trigger pinentry again
    gpg-connect-agent reloadagent /bye >/dev/null && \
        echo | gpg --clearsign >/dev/null && \
        echo "gpg: re-authenticated"
}

# Run a command with secrets from pass exported only for its lifetime, in the
# spirit of `aws-vault exec`. Each NAME's value is the first line of
# `pass show env/NAME`. Values are exported only in a subshell (never to this
# shell's environment or argv); any lookup failure, empty value, or special/typed
# NAME aborts before the command runs.
#
# Usage: xs [NAME...] -- cmd [args...]    e.g. xs SPLUNK_TOKEN -- claude
# cmd may be a command or a shell function; aliases are not expanded.
function xs() {
    setopt local_options no_xtrace    # keep secrets out of `set -x` traces
    # Validate argument syntax before decrypting anything. Locals are prefixed
    # _xs_ so a NAME does not resolve to one of them via ${(P)...}.
    local _xs_sep=${@[(i)--]}
    if (( _xs_sep >= $# )); then
        echo "usage: xs [NAME...] -- cmd [args...]" >&2
        return 2
    fi
    local -a _xs_names=("${@[1,_xs_sep-1]}") _xs_kv
    shift $_xs_sep
    local _xs_name _xs_val
    for _xs_name in "${_xs_names[@]}"; do
        # Keep in sync with the name filter in _xs.
        if [[ ! "$_xs_name" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]]; then
            echo "xs: invalid variable name: $_xs_name" >&2
            return 2
        fi
        # Special or typed parameters (USERNAME, SECONDS, integers, ...) would
        # not pass the value through to the command unchanged.
        if [[ ${(tP)_xs_name:-scalar} != (scalar|scalar-export) ]]; then
            echo "xs: cannot export $_xs_name (zsh ${(tP)_xs_name} parameter)" >&2
            return 2
        fi
    done
    for _xs_name in "${_xs_names[@]}"; do
        _xs_val=$(pass show "env/$_xs_name") || return
        _xs_val=${_xs_val%%$'\n'*}
        # pass lists a directory env/NAME/ (exit 0, first line "env/NAME")
        # when env/NAME.gpg is absent.
        if [[ "$_xs_val" == "env/$_xs_name" ]]; then
            echo "xs: env/$_xs_name is a directory, not a secret" >&2
            return 1
        fi
        if [[ -z "$_xs_val" ]]; then
            echo "xs: env/$_xs_name: first line is empty" >&2
            return 1
        fi
        _xs_kv+=("$_xs_name=$_xs_val")
    done
    ( (( ${#_xs_kv} )) && export "${_xs_kv[@]}"; "$@" )
}

# Completion: names under pass env/ before `--`, a normal command line after it.
function _xs() {
    local i=${words[(i)--]}
    if (( CURRENT > i )); then
        shift i words
        (( CURRENT -= i ))
        _normal
    else
        local expl
        local -a names=(${PASSWORD_STORE_DIR:-$HOME/.password-store}/env/*.gpg(N:t:r))
        # Same identifier rule as the regex in xs; keep the two in sync. xs still
        # rejects special/typed names.
        names=(${names:#(*[^A-Za-z0-9_]*|[0-9]*)})
        _wanted names expl 'pass env/ name' compadd -a names
    fi
}
(( $+functions[compdef] )) && compdef _xs xs

ssh-agent-start

[ -f "$HOME/.local.zsh" ] && source "$HOME/.local.zsh"

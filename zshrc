bindkey -v

autoload -Uz compinit vcs_info
compinit
setopt PROMPT_SUBST

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '%F{yellow}!'
zstyle ':vcs_info:git:*' unstagedstr '%F{magenta}+'
zstyle ':vcs_info:*' formats '%%B%%F{cyan}%c%u{%b}%%f%%b'
zstyle ':vcs_info:*' actionformats '[%b|%a]'

PROMPT='%B%K{blue}%n@%U%m%u%k %F{green}%~%f%b ${vcs_info_msg_0_} [%*]
%B%(?..[%?] )%b%B%F{white}%#%f%b '

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

alias vi="vim"
alias be="bundle exec"
alias ce="carton exec"
alias realpath="readlink -e"

export EDITOR=vim
#export GREP_OPTIONS="--color=auto"
export LANG="en_US.UTF-8"

export GOPATH=$HOME/go
export PATH=$HOME/.fzf/bin:$HOME/go/bin:$PATH

case "${OSTYPE}" in
    darwin*)
        alias ls="ls -G"
        alias zcat="gunzip -c"
        ;;
    linux*)
        alias ls="ls --color"
        ;;
esac

# functions
precmd() {
    vcs_info
}

pmdir () {
    cd $(dirname $(perldoc -lm $1))
}

lpmdir () {
    cd $(dirname $(carton exec -- perldoc -lm $1))
}

whereami () {
    echo -ne "\033]0;${USER}@${HOST}\007"
}

perldocvim () {
    FILE=$(perldoc -lm $*);
    if [[ -e $FILE ]]; then
        vim $FILE;
    fi
}

whereami
umask 022

# .ssh/config to have `HashKnownHosts no` will help
_cache_hosts=($([ -f ~/.ssh/known_hosts ] && cat ~/.ssh/known_hosts | cut -d',' -f1))

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh

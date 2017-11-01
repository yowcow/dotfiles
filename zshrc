bindkey -v

autoload -U promptinit compinit
compinit
promptinit
prompt walters
export PROMPT='%B%(?..[%?] )%b%n@%U%m%u> '

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
        umask 0002
        ;;
esac

# functions
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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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

export EDITOR=vim
export GREP_OPTIONS="--color=auto"
export LANG="en_US.UTF-8"

umask 0002

case "${OSTYPE}" in
    darwin*)
        alias ls="ls -G"
        alias zcat="gunzip -c"
        ;;
    linux*)
        alias ls="ls --color"
        ;;
esac

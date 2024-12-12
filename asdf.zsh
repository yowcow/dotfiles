for f in $HOME/.asdf/asdf.sh $HOME/.asdf/plugins/golang/set-env.zsh; do
    if [ -f $f ]; then
        . $f;
    fi
done

# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

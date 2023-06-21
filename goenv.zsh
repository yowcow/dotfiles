unset GOROOT
unset GOPATH

export GOENV_ROOT=$HOME/.goenv
export PATH=$GOENV_ROOT/bin:$PATH

eval "$(goenv init -)"

if [ ! -z "$GOROOT" ]; then
    export PATH="$GOROOT/bin:$PATH"
fi
if [ ! -z "$GOPATH" ]; then
    export PATH="$GOPATH/bin:$PATH"
fi

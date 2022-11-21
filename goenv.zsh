export GOENV_ROOT=$HOME/.goenv
export PATH=$GOENV_ROOT/bin:$HOME/go/bin:$PATH
#export GOENV_DISABLE_GOPATH=1

eval "$(goenv init -)"

if [ ! -z "$GOROOT" ]; then
    export PATH="$GOROOT/bin:$PATH";
fi

if [ ! -z "$GOPATH" ]; then
    export PATH="$GOPATH/bin:$PATH";
fi

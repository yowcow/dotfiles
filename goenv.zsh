unset GOROOT
unset GOPATH

export GOENV_ROOT=$HOME/.goenv
export GOPATH=$HOME/go
export PATH=$GOENV_ROOT/bin:$GOENV_ROOT/shims:$GOPATH/bin:$PATH
#export GOPRIVATE=github.com/voyagegroup

eval "$(goenv init -)"

#if [ ! -z "$GOROOT" ]; then
#    export PATH="$GOROOT/bin:$PATH"
#fi
#if [ ! -z "$GOPATH" ]; then
#    export PATH="$GOPATH/bin:$PATH"
#fi


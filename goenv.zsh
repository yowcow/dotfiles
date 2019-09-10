export GOENV_ROOT=$HOME/.goenv
export GOENV_DISABLE_GOPATH=1

PATH=$GOENV_ROOT/bin:$PATH

eval "$(goenv init -)"

export GOPATH=$HOME/go
PATH=$GOPATH/bin:$PATH

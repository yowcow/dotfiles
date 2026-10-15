#export CLAUDE_CODE_DISABLE_MOUSE=1
#export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1

function dude-high() {
    claude --model opus --effort high "$@"
}

function dude-low() {
    claude --model sonnet --effort high "$@"
}

if [ -d "$HOME/.grok/bin" ] && [[ ":$PATH:" != *":$HOME/.grok/bin:"* ]]; then
    export PATH="$HOME/.grok/bin:$PATH"
fi

if [ -d "$HOME/.grok/completions/zsh" ] && [[ " ${fpath[*]} " != *" $HOME/.grok/completions/zsh "* ]]; then
    fpath=("$HOME/.grok/completions/zsh" $fpath)
fi

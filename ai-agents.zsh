#export CLAUDE_CODE_DISABLE_MOUSE=1
#export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1

# Launch claude with SPLUNK_TOKEN from pass (see xs in zshrc). claude-* below
# call this function; `command claude` runs the binary without the token.
function claude() {
    xs SPLUNK_TOKEN -- command claude "$@"
}

function claude-high() {
    claude --model fable --effort medium "$@"
}

function claude-mid() {
    claude --model opus --effort medium "$@"
}

function claude-low() {
    claude --model sonnet --effort medium "$@"
}

if [ -d "$HOME/.grok/completions/zsh" ] && [[ " ${fpath[*]} " != *" $HOME/.grok/completions/zsh "* ]]; then
    fpath=("$HOME/.grok/completions/zsh" $fpath)
fi

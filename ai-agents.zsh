#export CLAUDE_CODE_DISABLE_MOUSE=1
#export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1

# claude code: high/low tier exec
function claude-high() {
    CLAUDE_CODE_EFFORT_LEVEL=high claude --model opus "$@"
}

function claude-low() {
    CLAUDE_CODE_EFFORT_LEVEL=medium CLAUDE_CODE_SUBAGENT_MODEL=opus claude --model sonnet "$@"
}

if [ -d "$HOME/.grok/bin" ] && [[ ":$PATH:" != *":$HOME/.grok/bin:"* ]]; then
    export PATH="$HOME/.grok/bin:$PATH"
fi

if [ -d "$HOME/.grok/completions/zsh" ] && [[ " ${fpath[*]} " != *" $HOME/.grok/completions/zsh "* ]]; then
    fpath=("$HOME/.grok/completions/zsh" $fpath)
fi

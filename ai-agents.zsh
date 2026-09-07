#export CLAUDE_CODE_DISABLE_MOUSE=1
export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1
#export CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1

# claude code: high/low tier exec
function claude-high() {
    claude --model opus --effort medium "$@"
}

function claude-low() {
    CLAUDE_CODE_SUBAGENT_MODEL=opus claude --model sonnet --effort medium "$@"
}

export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C

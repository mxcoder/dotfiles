#!/bin/bash
## Path related exports
# shellcheck disable=SC1091

# NPM / Node
if [ -d "$HOME/.npm/bin" ] ; then
    export NPM_HOME=$HOME/.npm
    export PATH="$HOME/.npm/bin/:$PATH"
fi

# NVM
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "${NVM_DIR}/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && source "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion
fi

# RVM
if [ -d "$HOME/.rvm" ]; then
    export RVM_HOME=$HOME/.rvm
    PATH="$RVM_HOME/bin:$PATH" # Add RVM to PATH for scripting
fi

# Rust
if [ -d "$HOME/.cargo" ]; then
    export CARGO_HOME="$HOME/.cargo"
    source "${CARGO_HOME}/env"
fi

# Basic user bin libraries
export PATH="$HOME/bin:$PATH"

# Add non-versioned `.extra/bin` to the `$PATH`
[ -d "$DOTFILES/.extra/bin" ] && export PATH="$DOTFILES/.extra/bin:$PATH"

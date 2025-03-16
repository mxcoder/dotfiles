#!/bin/bash
## Path related exports
# shellcheck disable=SC1091

# Basic user bin libraries
if [[ $PATH != *"$HOME/bin"* ]]; then
    export PATH="$HOME/bin:$PATH"
fi

# NPM / Node
if [ -d "$HOME/.npm/bin" ] ; then
    export NPM_HOME="$HOME/.npm"
    export PATH="$NPM_HOME/bin:$PATH"
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

# Golang
if [ -n "$GO_HOME" ]; then
    export GOPATH="$HOME/go"
    if [[ $PATH != *"$GO_HOME/bin"* ]]; then
        export PATH="$GO_HOME/bin:$PATH"
    fi
    if [[ $PATH != *"$GOPATH/bin"* ]]; then
        export PATH="$GOPATH/bin:$PATH"
    fi
fi

# Rust/Cargo
if [ -d "$HOME/.cargo" ]; then
    export CARGO_HOME="$HOME/.cargo"
    if [[ $PATH != *"$CARGO_HOME/bin"* ]]; then
        export PATH="$CARGO_HOME/bin:$PATH"
    fi
fi

# Sdkman
if [ -d "$HOME/.sdkman" ]; then
    [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Add non-versioned `.extra/bin` to the `$PATH`
[ -d "$DOTFILES/.extra/bin" ] && export PATH="$DOTFILES/.extra/bin:$PATH"

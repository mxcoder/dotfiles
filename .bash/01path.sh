## Path related exports

# Basic user bin libraries
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/bin"

# NPM / Node
if [ -d "$HOME/.npm/bin" ] ; then
    export NPM_HOME=$HOME/.npm
    PATH="$HOME/.npm/bin:$PATH"
fi

# RVM
if [ -d "$HOME/.rvm" ]; then
    export RVM_HOME=$HOME/.rvm
    PATH=$PATH:$RVM_HOME/bin # Add RVM to PATH for scripting
fi

# Add non-versioned `.extra/bin` to the `$PATH`
[ -d $DOTFILES/.extra/bin ] && export PATH="$DOTFILES/.extra/bin:$PATH"

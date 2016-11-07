## Path related exports

# Composer
if [ -d "$HOME/.composer/vendor/bin" ] ; then
    PATH="$HOME/.composer/vendor/bin:$PATH"
fi

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

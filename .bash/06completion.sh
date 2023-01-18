#!/bin/bash
## Autocompletion engines

if ! shopt -oq posix; then
    if [ -d "$HOME/.bash_completion.d" ]; then
        FILES=$( find "$HOME/.bash_completion.d/" -type l -o -type f -name "*.bash" )
        for file in $FILES; do
            source "$file"
        done
    fi
fi

if [ -n "$(exists starship)" ] && [ ! -f "$HOME/.bash_completion.d/03-starship.bash" ]; then
    echo "Installing starship bash_completion file"
    starship completions bash > "$HOME/.bash_completion.d/03-starship.bash"
fi

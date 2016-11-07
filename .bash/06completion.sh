## Autocompletion engines

if ! shopt -oq posix; then
    if [ -d "$HOME/.bash_completion.d" ]; then
        for file in `find $HOME/.bash_completion.d/ -type l -o -type f`; do
            source $file
        done
    fi
fi

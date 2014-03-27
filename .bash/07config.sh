## Configure options

# Creates symlinks for .dotfiles in $HOME
for file in $DOTFILES/.conf/*; do
    current="$HOME/."`basename $file`
    if [ ! -L "$current" ]; then
        [ -f "$current" ] && mv "$current" "$current.backup"
        [ -e "$file" ] && ln -s "$file" "$current"
    fi
done
unset current
unset file


# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

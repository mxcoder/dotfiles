## Configure options

# Creates symlinks for .dotfiles in $HOME
for file in $DOTFILES/.conf/*; do
    current="$HOME/."`basename $file`
    [ -f "$current" ] && [ ! -L "$current" ] && mv "$current" "$current.backup"
    [ -r "$file" ] && [ -f "$file" ] && [ ! -L "$current" ] && ln -s "$file" "$current"
done
unset current
unset file


# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

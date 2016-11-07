## Configure options
CONFS_DIR="$DOTFILES/.conf/";

# Creates symlinks for .dotfiles in $HOME
for file in `find $CONFS_DIR -type f`; do
    current="$HOME/${file/$CONFS_DIR/.}";
    if [ ! -e "$current" ]; then
        mkdir -p `dirname $current`
        ln -fs "$file" "$current"
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

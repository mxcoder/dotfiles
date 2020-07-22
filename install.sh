# Install configuration symlinks

## Configure options
CONFS_DIR="$DOTFILES/.conf/";

# Creates symlinks for .dotfiles in $HOME
for file in `find $CONFS_DIR -type f`; do
    current="$HOME/${file/$CONFS_DIR/.}";
    if [ -f "$current" ]; then
        cp "$current" "$current.bak"
    fi
    if [ ! -e "$current" ]; then
        mkdir -p `dirname $current`
        ln -fs "$file" "$current"
    fi
done
unset current
unset file

# Install non-versioned bash scripts

## Link bins

for file in $DOTFILES/bin/*; do
    name=`basename $file`
    [ ! -L "$HOME/bin/$name" ] && ln -s $file "$HOME/bin/$name"
done
unset file name

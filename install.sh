#!/bin/bash
# Install configuration symlinks

## Configure options
CONFS_DIR="$DOTFILES/.conf/";

# Creates symlinks for .dotfiles in $HOME
FILES=$(find "$CONFS_DIR" -type f)
for FILE in $FILES; do
    TARGET=$(realpath "$HOME/${FILE/$CONFS_DIR/.}")
    if [ -f "$TARGET" ]; then
        cp "$TARGET"{,.bak}
    fi
    if [ ! -e "$TARGET" ]; then
        mkdir -p "$(dirname "$TARGET")"
        ln -fs "$FILE" "$TARGET"
    fi
done
unset FILES FILE TARGET

# Install non-versioned bash scripts

## Link bins

FILES=$(find "$DOTFILES"/bin/ -executable)
for FILE in $FILES; do
    NAME=$(basename "$FILE")
    if [ ! -L "$HOME/bin/$NAME" ]; then
        ln -s "$FILE" "$HOME/bin/$NAME"
    fi
done
unset FILES FILE NAME

#!/bin/bash

## Main entry bash
## Most of this was pirated from https://github.com/mathiasbynens/dotfiles

# Get .dotfiles folder
export DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load the shell dotfiles, and then some:
for file in $DOTFILES/.bash/*; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

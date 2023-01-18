#!/bin/bash
## Source .extra

for file in "$DOTFILES"/.extra/*.sh; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

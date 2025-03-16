#!/bin/bash
# shellcheck disable=SC1090

## Main entry bash
## Most of this was pirated from https://github.com/mathiasbynens/dotfiles

if [ -n "$DOTFILES_INITIATED" ]; then
    return
fi

DOTFILES_INITIATED="$(date --rfc-3339=seconds)"
export DOTFILES_INITIATED

# Get .dotfiles folder
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Load the shell dotfiles, and then some:
for file in "$DOTFILES"/.bash/*; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

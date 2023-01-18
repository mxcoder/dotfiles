#!/bin/bash
# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# if direnv is available, use it
if [ -n "$(command -v direnv)" ]; then
    eval "$(direnv hook bash)"
fi

#!/bin/bash
## Exported options and variables

# Environment
export WORKHOME=$HOME/Work

# Make nano the default editor - that's how I roll, deal with it.
export EDITOR="nano"

# Larger bash history (allow 32³ entries; default is 500)
export HISTSIZE=5000
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups
# Make some commands not show up in history
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
# Highlight section titles in manual pages
export LESS_TERMCAP_md="$ORANGE"

# Don’t clear the screen after quitting a manual page
export MANPAGER="less -X"

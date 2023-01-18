#!/bin/bash
## Common functions

# eXecute Silently (no errors shown)
function xs() {
    eval "$1" 2> /dev/null;
}

# checks if a given command name is actually executable
function exists () {
    command -v "$1" 2>&1 /dev/null
}

# File functions

# Tries to open any file according to system settings
function open() {
    local FILE=${1:-"."}
    echo "opening $(file "$FILE")"
    if exists gnome-open; then
        xs "gnome-open $FILE"
    elif exists xdg-open; then
        xs "xdg-open $FILE"
    fi
}

# `o` with no arguments opens current directory, otherwise opens the given
# location
function o() {
    if [ $# -eq 0 ]; then
        open .
    else
        open "$@"
    fi
}

# `s` with no arguments opens the current directory in Sublime Text, otherwise
# opens the given location
function s() {
    if [ $# -eq 0 ]; then
        subl .
    else
        subl "$@"
    fi
}

# Create a new directory and enter it
function mkd() {
    mkdir -p "$1" && cd "$1" || return
}

# determine size of a file or total size of a directory
function fs() {
    if du -b /dev/null > /dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi
    if [[ -n "$*" ]]; then
        du $arg -- "$*" | sort -rh
    else
        du $arg .[^.]* ./* | sort -rh
    fi
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
    tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX
}

# finds duplicated files
function dupes() {
    if [ $# -eq 0 ]; then
        local PT="./"
    else
        local PT="$*"
    fi
    find "$PT" -not -empty -type f -printf "%s\n" | sort -rn | uniq -d | xargs -I{} -n1 find -type f -size {}c -print0 | xargs -0 md5sum | sort | uniq -w32 --all-repeated=separate
}

# print nth line (print_line FILE nth)
function print_line() {
    sed "${2}q;d" "$1"
}

# create a data url from a file
function dataurl() {
    local -r mimeType=$(file -b --mime-type "$1")
    if [[ $mimeType == text/* ]]; then
        mimeType="${mimeType};charset=utf-8"
    fi
    echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Other functions

# To system-wide clipboard
# http://madebynathan.com/2011/10/04/a-nicer-way-to-use-xclip/
# # A shortcut function that simplifies usage of xclip.
# - Accepts input from either stdin (pipe), or params.
# ------------------------------------------------
function cb() {
    local _scs_col="\e[0;32m"
    local _wrn_col='\e[1;31m'
    local _trn_col='\e[0;33m'
    # Check that xclip is installed.
    if ! type xclip > /dev/null 2>&1; then
        echo -e "$_wrn_col""You must have the 'xclip' program installed.\e[0m"
    # Check user is not root (root doesn't have access to user xorg server)
    elif [[ "$USER" == "root" ]]; then
        echo -e "$_wrn_col""Must be regular user (not root) to copy a file to the clipboard.\e[0m"
    else
        # If no tty, data should be available on stdin
        if ! [[ "$( tty )" == /dev/* ]]; then
            input="$(< /dev/stdin)"
        # Else, fetch input from params
        else
            input="$*"
        fi
        if [ -z "$input" ]; then  # If no input, print usage message.
            echo "Copies a string to the clipboard."
            echo "Usage: cb <string>"
            echo "       echo <string> | cb"
        else
            # Copy input to clipboard
            echo -n "$input" | xclip -selection c
            # Truncate text for status
            if [ ${#input} -gt 80 ]; then input="$(echo "$input" | cut -c1-80)$_trn_col...\e[0m"; fi
                # Print status.
                echo -e "$_scs_col""Copied to clipboard:\e[0m $input"
            fi
    fi
}
export -f cb

# simple calculator
function calc() {
    local result=""
    result="$(printf 'scale=10;%s\n' "$*" | bc --mathlib | tr -d '\\\n')"
    #                       └─ default (when `--mathlib` is used) is 20
    #
    if [[ "$result" == *.* ]]; then
        # improve the output for decimal numbers
        printf '%s' "$result" |
        sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
            -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
            -e 's/0*$//;s/\.$//'   # remove trailing zeros
    else
        printf '%s' "$result"
    fi
    printf "\n"
}

# start a python http server from current directory, optionally specifying the port
# (Requires Python 3)
function miniserver() {
    local port="${1:-8080}"
    python3 -m http.server "$port"
    open "http://127.0.0.1:${port}/"
}

# controls brightness with xrandr
function brightness() {
    local bv="${1:-0.8}"
    for MON in $(xrandr | grep ' connected' | cut -f1 -d' '); do
        xrandr --output "$MON" --brightness "$bv"
    done
}

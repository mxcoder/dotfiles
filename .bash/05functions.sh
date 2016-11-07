## Common functions

# eXecute Silently (no errors shown)
xs() {
    eval "$1" 2> /dev/null;
}

# Tries to open any file according to system settings
open() {
    local file=${@:-"."}
    echo opening $file
    file $file
    if type gnome-open > /dev/null 2>&1; then
        xs "gnome-open $file"
    elif type xdg-open > /dev/null 2>&1; then
        xs "xdg-open $file"
    fi
}

# Create a new directory and enter it
mkd() {
    mkdir -p "$1" && cd "$1"
}

# Determine size of a file or total size of a directory
fs() {
    if du -b /dev/null > /dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi
    if [[ -n "$@" ]]; then
        du $arg -- "$@" | sort -rh
    else
        du $arg .[^.]* * | sort -rh
    fi
}

# Visual editor
veditor() {
    if type subl > /dev/null 2>&1; then
        subl $1 &
    else
        gedit $1 &
    fi
}
export -f veditor

# To system-wide clipboard
# http://madebynathan.com/2011/10/04/a-nicer-way-to-use-xclip/
# # A shortcut function that simplifies usage of xclip.
# - Accepts input from either stdin (pipe), or params.
# ------------------------------------------------
cb() {
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
            if [ ${#input} -gt 80 ]; then input="$(echo $input | cut -c1-80)$_trn_col...\e[0m"; fi
                # Print status.
                echo -e "$_scs_col""Copied to clipboard:\e[0m $input"
            fi
    fi
}
export -f cb
# Aliases / functions leveraging the cb() function
# ------------------------------------------------
# Copy contents of a file
function cbf() { cat "$1" | cb; }

# Copy current working directory
alias cbwd="pwd | cb"
# Copy most recent command in bash history
alias cbhs="cat $HISTFILE | tail -n 1 | cb"

# Haste client
# https://github.com/seejohnrun/haste-client
haste() { a=$(cat); curl -X POST -s -d "$a" http://hastebin.com/documents | awk -F '"' '{print "http://hastebin.com/"$4}'; }

# Puu.sh client
puush() { puush-client "$1" | cb; }
puushscreen() { puush-screenshot $1; }
export puushscreen
alias psh="puush"
alias pshc="puushscreen"

# Sinergy start/stop
sinergy-control() {
    local msg=""
    local spid=`pidof synergys`
    if ([ -z "$1" ] && [ ! -z "$spid" ]) || [ "off" = "$1" ]; then
        killall synergys
        msg="Stopped"
    elif ([ -z "$1" ] && [ -z "$spid" ]) || [ "on" = "$1" ]; then
        synergys --daemon --restart
        msg="Restarted"
    fi
    if [ ! -z "$msg" ]; then
        notify-send -i terminal "Sinergy" "$msg"
    fi
}
alias sny="sinergy-control"

# Simple calculator
function calc() {
    local result=""
    result="$(printf "scale=10;$*\n" | bc --mathlib | tr -d '\\\n')"
    #                       └─ default (when `--mathlib` is used) is 20
    #
    if [[ "$result" == *.* ]]; then
        # improve the output for decimal numbers
        printf "$result" |
        sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
            -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
            -e 's/0*$//;s/\.$//'   # remove trailing zeros
    else
        printf "$result"
    fi
    printf "\n"
}

# Create a data URL from a file
function dataurl() {
    local mimeType=$(file -b --mime-type "$1")
    if [[ $mimeType == text/* ]]; then
        mimeType="${mimeType};charset=utf-8"
    fi
    echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Start a python http server from current directory, optionally specifying the port
# (Requires Python 3)
function miniserver() {
    local port="${1:-8080}"
    python3 -m http.server $port
    sleep 1 && open "http://127.0.0.1:${port}/" &
}

# Start a PHP server from current directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
function phpserver() {
    local port="${1:-4000}"
    php -S "127.0.0.1:${port}" -t .
    sleep 1 && open "http://127.0.0.1:${port}/" &
}

# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
    perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
    # print a newline unless we’re piping the output to another program
    if [ -t 1 ]; then
        echo # newline
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

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
    tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX
}


function brightness() {
    local bv="${1:-0.8}"
    xrandr --output LVDS1 --brightness $bv
    xrandr --output HDMI1 --brightness $bv
}

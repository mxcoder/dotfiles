#!/bin/bash
## Sets cli prompt

# @gf3’s Sexy Bash Prompt, inspired by “Extravagant Zsh Prompt”
# Shamelessly copied from https://github.com/gf3/dotfiles
# Screenshot: http://i.imgur.com/s0Blh.png

#if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
#    export TERM=gnome-256color
#elif infocmp xterm-256color >/dev/null 2>&1; then
#    export TERM=xterm-256color
#fi

if tput setaf 1 &> /dev/null; then
    tput sgr0
    if [[ $(tput colors) -ge 256 ]] 2>/dev/null; then
        MAGENTA=$(tput setaf 9)
        ORANGE=$(tput setaf 172)
        GREEN=$(tput setaf 190)
        PURPLE=$(tput setaf 141)
        WHITE=$(tput setaf 0)
    else
        MAGENTA=$(tput setaf 5)
        ORANGE=$(tput setaf 4)
        GREEN=$(tput setaf 2)
        PURPLE=$(tput setaf 1)
        WHITE=$(tput setaf 7)
    fi
    BOLD=$(tput bold)
    RESET=$(tput sgr0)

    LESS_TERMCAP_mb=$(tput bold; tput setaf 2) # green
    LESS_TERMCAP_md=$(tput bold; tput setaf 6) # cyan
    LESS_TERMCAP_me=$(tput sgr0)
    LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4) # yellow on blue
    LESS_TERMCAP_se=$(tput rmso; tput sgr0)
    LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 7) # white
    LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
    LESS_TERMCAP_mr=$(tput rev)
    LESS_TERMCAP_mh=$(tput dim)
    LESS_TERMCAP_ZN=$(tput ssubm)
    LESS_TERMCAP_ZV=$(tput rsubm)
    LESS_TERMCAP_ZO=$(tput ssupm)
    LESS_TERMCAP_ZW=$(tput rsupm)
    export LESS_TERMCAP_mb
    export LESS_TERMCAP_md
    export LESS_TERMCAP_me
    export LESS_TERMCAP_so
    export LESS_TERMCAP_se
    export LESS_TERMCAP_us
    export LESS_TERMCAP_ue
    export LESS_TERMCAP_mr
    export LESS_TERMCAP_mh
    export LESS_TERMCAP_ZN
    export LESS_TERMCAP_ZV
    export LESS_TERMCAP_ZO
    export LESS_TERMCAP_ZW
else
    MAGENTA="\033[1;31m"
    ORANGE="\033[1;33m"
    GREEN="\033[1;32m"
    PURPLE="\033[1;35m"
    WHITE="\033[1;37m"
    BOLD=""
    RESET="\033[m"
fi

export MAGENTA
export ORANGE
export GREEN
export PURPLE
export WHITE
export BOLD
export RESET

function parse_git_dirty() {
    [[ -d ".git" && -n "$(git status --porcelain)" ]] && echo "*"
}

function parse_git_branch() {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}

export DEFAULT_PS1="\[${BOLD}${MAGENTA}\]\u\[$WHITE\]@\[$ORANGE\]\h\[$WHITE\][\[$GREEN\]\w\[$WHITE\]]\$([[ -n \$(git branch 2> /dev/null) ]] && echo \":\")\[$PURPLE\]\$(parse_git_branch)\[$BLUE\]\[$RESET\]\n\$>"
export PS1=$DEFAULT_PS1
export PS2="\[$ORANGE\]→ \[$RESET\]"

function reset_prompt {
    export PS1=$DEFAULT_PS1
}

# see https://starship.rs/
# if available, use it
if [ -n "$(command -v starship)" ]; then
    eval "$(starship init bash)"
fi

if [ -x "$HOME/.cargo/bin/starship" ]; then
    eval "$("$HOME"/.cargo/bin/starship init bash)"
fi

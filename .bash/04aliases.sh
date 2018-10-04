## Aliases

# Easier navigation
alias -- -="cd -"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# List all files colorized in long format
alias l="ls -lF --color=auto"
# List all files colorized in long format, including dot files
alias la="ls -laF --color=auto"
# List only directories
alias lsd="ls -lF --color=auto | grep --color=never '^d'"
# Always use color output for `ls`
alias ls="command ls --color=auto"

# Shortcuts
alias cls='printf "\033c"'
alias e="editor"
alias ve="veditor"
alias z="screen -dRR"
alias d="cd ~/Dropbox"
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias cdd="cd $DOTFILES"
alias cdw="cd $WORKHOME"
alias g="git"
alias gti="git"

# Enable aliases to be sudo’ed
alias sudo='sudo '

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias lip="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Enhanced WHOIS lookups
alias whois="whois -h whois-servers.net"

# View HTTP traffic
alias sniff="sudo ngrep -d $(ifconfig -a | grep RUNNING | grep -v 'tun0\|lo' | cut -d':' -f1) -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i $(ifconfig -a | grep RUNNING | grep -v 'tun0\|lo' | cut -d':' -f1) -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# URL-encode strings
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

# One of @janmoesen’s ProTip™s
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
    alias "$method"="lwp-request -m '$method'"
done

alias nginx-restart='sudo service nginx restart'
alias hosts='sudo editor /etc/hosts'
alias notify='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias topsizes="find . -iwholename '*\.git\/*' -prune -o -type f -printf '%s %p\n' | numfmt --to=iec-i | sort -hr | head -n10"

## Docker

# Shows images by size
alias dockerim='docker images --format "{{.Size}}\t{{.Repository}}\t{{.Tag}}\t{{.ID}}" | sed "s/ //" | sort -h -r | column -t'
# Kill all running containers.
alias dockerkillall='docker kill $(docker ps -q)'
# Delete all stopped containers.
alias dockercleanc='printf "\n>>> Deleting stopped containers\n\n" && docker rm $(docker ps -a -q)'
# Delete all untagged images.
alias dockercleani='printf "\n>>> Deleting untagged images\n\n" && docker rmi $(docker images -q -f dangling=true)'
# Delete all stopped containers and untagged images.
alias dockerclean='dockercleanc || true && dockercleani'

## Extra non-versioned stuff

# Add non-versioned `.extra/bin` to the `$PATH`
[ -d $DOTFILES/.extra/bin ] && export PATH="$DOTFILES/.extra/bin:$PATH"

# Source non-versioned bash scripts
for file in $DOTFILES/.extra/*.sh; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

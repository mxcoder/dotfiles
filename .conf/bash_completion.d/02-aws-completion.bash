aws_completer_path=$(which aws_completer)

if [ -f $aws_completer_path ]; then
    complete -C $aws_completer_path aws
fi

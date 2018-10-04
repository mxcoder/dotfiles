#!/bin/sh

git filter-branch --env-filter '

OLD_EMAIL="${1:-ricardo@gumgum.com}"
CORRECT_EMAIL="${2:-ricardoe@gmail.com}"
CORRECT_NAME="${3:-Ricardo Vega}"

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags

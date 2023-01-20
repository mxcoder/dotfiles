#!/bin/bash

# starship.rs for nice prompts
starship_path=$(which starship)
if [ -e "$starship_path" ]; then
    source <(starship completions bash)
fi

#!/bin/bash

# AWS CLI
bin_path=$(which pack)

if [ -x "$bin_path" ]; then
    source $("$bin_path" completion)
fi

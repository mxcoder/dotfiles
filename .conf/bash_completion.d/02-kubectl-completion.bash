#!/bin/bash

# kubectl
kubectl_path=$(which kubectl)
if [ -e "$kubectl_path" ]; then
    source <(kubectl completion bash)
fi

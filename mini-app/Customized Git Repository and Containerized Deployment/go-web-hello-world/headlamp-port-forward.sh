#!/bin/bash

POD_NAME=$(kubectl get pods -n kube-system --no-headers | awk '/^headlamp-/ {print $1; exit}')

if [ -z "$POD_NAME" ]; then
    echo "Headlamp pod not found"
    exit 1
fi

echo "$(date) Using pod: $POD_NAME"

exec kubectl port-forward -n kube-system \
    pod/$POD_NAME \
    31081:4466 \
    --address 0.0.0.0
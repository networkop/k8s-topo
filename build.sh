#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Must provide docker hub username"
    exit 1
fi

docker build --no-cache -t k8s-topo .
docker tag k8s-topo $1/k8s-topo
docker push $1/k8s-topo
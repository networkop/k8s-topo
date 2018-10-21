#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Must provide docker hub username"
    exit 1
fi

docker build -t qrtr .
docker tag qrtr $1/qrtr
docker push $1/qrtr
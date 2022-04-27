#!/bin/bash
repo=$1
if [[ -z $repo ]]; then
    echo "Please pass repo argument"
    exit 1
fi

build() {
    local image=$1
    docker build -t $repo/$image-jdk11.0.15 --build-arg BASE_IMAGE=datastax/$image .
}

ls280version=2.8.0_1.1.40
build lunastreaming:$ls280version
build lunastreaming-all:$ls280version
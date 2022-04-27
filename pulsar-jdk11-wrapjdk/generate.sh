#!/bin/bash
repo=$1

build() {
    local image=$1
    docker build -t $repo/$image-jdk11.0.15 --build-arg FROM_IMAGE=datastax/$image .
}

ls280version=2.8.0_1.1.37
build datastax/lunastreaming:$ls280version
build datastax/lunastreaming-all:$ls280version
# Usage:
# docker build -t nicoloboschi/lunastreaming-all:2.8.3_1.0.9-jdk17 --build-arg BASE_IMAGE=datastax/lunastreaming-all:2.8.3_1.0.9 .

ARG BASE_IMAGE
FROM $BASE_IMAGE

RUN apt-get update && apt-get install openjdk-17-jdk -y && update-java-alternatives --set java-1.17.0-openjdk-amd64
ENV JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64


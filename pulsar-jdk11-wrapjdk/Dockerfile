ARG BASE_IMAGE=
FROM $BASE_IMAGE

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
USER 0
RUN apt-get update && apt-get -y install --no-install-recommends openjdk-11-jdk-headless
USER 10000
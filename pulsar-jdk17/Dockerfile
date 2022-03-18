FROM apachepulsar/pulsar-all:2.9.1

RUN apt-get update && apt-get install openjdk-17-jdk -y && update-java-alternatives --set java-1.17.0-openjdk-amd64
ENV JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64
ENV PULSAR_EXTRA_OPTS='--add-opens java.base/java.util.zip=ALL-UNNAMED'


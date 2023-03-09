ARG FROM=datastax/lunastreaming-all:2.10_3.4
FROM ${FROM}

USER 0
COPY replace.sh /pulsar/replace.sh
COPY connectors/* /pulsar/tmp-connectors/
RUN /pulsar/replace.sh
#RUN echo $(/bin/bash -ex /pulsar/replace.sh) > build-debug.log
USER 10000
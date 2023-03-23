ARG FROM
FROM ${FROM}

USER 0
COPY replace.sh /pulsar/replace.sh
COPY libs/* /pulsar/tmp-lib/
RUN /pulsar/replace.sh
#RUN echo $(/bin/bash -ex /pulsar/replace.sh) > build-debug.log
USER 10000
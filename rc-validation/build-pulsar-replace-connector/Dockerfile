ARG FROM=datastax/lunastreaming-experimental:2.10_3.4
FROM ${FROM}

ARG DELETE_PATTERN

USER 0
RUN rm -rf /pulsar/connectors/$DELETE_PATTERN
COPY ./*nar /pulsar/connectors
USER 10000
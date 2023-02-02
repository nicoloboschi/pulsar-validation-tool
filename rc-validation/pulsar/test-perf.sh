messages=100
messages_per_txn=10
total_txn=$((messages / messages_per_txn))
/pulsar/bin/pulsar-perf produce -m $messages --exit-on-failure -t 1 consume-topic 

/pulsar/bin/pulsar-perf transaction --topics-c consume-topic --topics-p produce-topic -threads 10 \
                -ntxn $total_txn -ss sub -nmp $messages_per_txn -nmc $messages_per_txn
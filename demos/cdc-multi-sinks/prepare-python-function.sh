docker cp pulsar_transform.py friendly_turing:/pulsar/pulsar_transform.py

docker exec -it friendly_turing bin/pulsar-admin functions localrun \
  --tenant public \
  --namespace default \
  --name test_function_xx \
  --classname pulsar_transform.ExclamationFunction \
  --py /pulsar/pulsar_transform.py \
  --inputs persistent://public/default/data-ks1.table1 \
  --output persistent://public/default/events-ks1.table2
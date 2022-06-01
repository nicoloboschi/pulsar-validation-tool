              found="false"
              while [[ "found" != "true" ]]
              do
                output='
 count
-------
  8000

(1 rows)

Warnings :
Aggregation query used without partition key'
                echo "SELECT * FROM pulsar_table;"
                echo "$output"
                res=$(echo "$output" | grep " {{ num_messages }} " | tr -d ' ')
                if [[ -n "$res" ]]; then
                  found="true"
                fi
                sleep 5
              done
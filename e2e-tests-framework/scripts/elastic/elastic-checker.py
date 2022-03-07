import json, time, sys
from urllib.request import urlopen

es_hostname = sys.argv[1]
es_index_name = sys.argv[2]
es_expected_data = sys.argv[3]

def index_contains_data(hostname, index_name, data):
    url = "http://%s:9200/%s/_search" % (hostname, index_name)
    try:
        contents = urlopen(url).read()
        print("reading from %s" % url)
        as_json = json.loads(contents)
        print(as_json)
        if (str(as_json["hits"]["hits"][0]["_source"]["count"]) == str(data)):
            return True
        print("Found JSON, but it does not contain expected data: %s" % data)
        return False
    except Exception as err:
        print(err)
        return False

found = False
attempts_count = 0
max_attempts = 30
while (attempts_count < max_attempts):
    found = index_contains_data(es_hostname, es_index_name, es_expected_data)
    if found:
        break
    time.sleep(5)
    max_attempts += 1

if found:
    print("Test passed!")
else:
    raise Exception("Test failed!")
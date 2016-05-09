#!/bin/bash

function stress_it(){
  stop=false

  until [ $stop == true ]; do
    track_headers=$(mktemp "header.XXXX")

    curl --cert $DEV_CERT_PEM --key $DEV_CERT_PEM --insecure \
         --include \
         --dump-header $track_headers \
         --header "Content-Type: application/json" \
         --request POST \
         --silent \
         --data '{"components":[{"id":"stream-icons","endpoint":"https://morph.test.api.bbci.co.uk/data/bbc-morph-lx-temp-icons/version/1.0.0?timeout=5","must_succeed":true},{"id":"integralist","endpoint":"https://gist.githubusercontent.com/Integralist/09169539877be2676cc896affdcba029/raw/a519ef229a3a137e671d8daa484ef340348d5ece/envelope-2.json","must_succeed":true}]}' \
         https://requester.mozart.test.api.bbci.co.uk/collect

    status_code=$(cat $track_headers | head -n 1 | cut -d ' ' -f 2)

    if [ $status_code -ne 200 ]; then
      stop=true
    fi

    rm $track_headers
  done
}

for i in {1..10}
do
  stress_it &
done

ps aux | grep 'curl --cert'

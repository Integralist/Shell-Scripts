#!/bin/bash
#
# Example:
#   /bin/bash ./watchtower.sh
#
# Description:
#   Curls the specified URLs in parallel and checks their response status codes
#   It then sends any non-200 status code responses to Slack

function cleanup() {
  rm results.txt
  rm temp.txt
}

function pull() {
  local base=$1
  local urls=("${!2}")

  for resource in "${urls[@]}"
  do
    curl $base$resource --head \
                        --location \
                        --silent \
                        --output /dev/null \
                        --connect-timeout 2 \
                        --write-out "%{url_effective} %{http_code}\n" &
  done

  wait
}

function parse() {
  local results=$1
  local remote=https://hooks.slack.com/services/foo/bar/baz # CHANGE THIS TO YOUR OWN SLACK HOOK

  cat $results | awk '!/200/ { print $2 ": " $1 }' > temp.txt

  while read line; do
    curl --header "Content-Type: application/json" \
         --silent \
         --output /dev/null \
         --request POST \
         --data "{\"text\": \"$line\"}" $remote &
  done < temp.txt

  wait

  display temp.txt
}

function display() {
  printf "\n\n"
  cat $1
  printf "\n\n"
}

trap cleanup EXIT

endpoints=(
  /newsbeat
  /newsbeat/popular
  /newsbeat/topics
  /newsbeat/topics/entertainment
  /newsbeat/topics/surgery
  /newsbeat/article/32792353/im-engaged-but-will-i-ever-be-able-to-marry-my-boyfriend
)

pull http://bbc.co.uk endpoints[@] > results.txt
display results.txt
parse results.txt

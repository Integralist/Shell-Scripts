#!/bin/bash
#
# Example:
#   /bin/bash ./smoke-tests.sh www
#
# Description:
#   Requests all defined URLs and checks it contains an expected response header
#   Exits immediately if any of the tests fail

function smoke {
  local bold=$(tput bold)
  local normal=$(tput sgr0)

  local url=$1
  local headers=${2:-''}

  if [[ $env == 'www' ]]; then
    local default_header='-H "X-A-Default-Header-For-Every-Request: 123"'
  else
    local default_header=''
  fi

  if [[ "$#" -lt 3 ]]; then
    local expected_response_header=${2:-''}
    printf "\nURL: $url\nHEADERS: $default_header\nEXPECTATION: ${bold}$expected_response_header${normal} \n"
  else
    local expected_response_header=${3:-''}
    printf "\nURL: $url\nHEADERS: $default_header $headers\nEXPECTATION: ${bold}$expected_response_header${normal} \n"
  fi

  local response=$(eval "curl -sI $default_header $headers $url")

  printf "\nRESPONSE…\n\n"
  actual_response_header=(${expected_response_header//:/ })
  echo "$response" | awk "/$actual_response_header/ && found == 0 {found = 1; print \"${bold}\"; print; print \"${normal}\"; next} {print}"

  if ! [[ $response =~ "$expected_response_header" ]]; then
    echo "X"
    exit 1
  else
    echo "√"
  fi
}

env=${1:-'stage'}
auth='user:pass@'
host="https://$auth$env.example.com"
noauth_host="https://$env.example.com"

if [[ $env == 'www' ]]; then
  host=$noauth_host
fi

smoke "$host/foo/bar" '-H "User-Agent: iphone"' 'x-some-expected-response-header: beepboop'

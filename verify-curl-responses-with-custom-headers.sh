#!/bin/bash

function verify {
  local url=$1
  local headers=${2:-''}
  local default_header='-H "X-Enable-Something: on"'

  printf "\n\nURL: $url\nHEADERS: $default_header $headers\n\n"
  local response=$(eval "curl -sI $default_header $headers $url")
  echo "response: $response"
  printf "\n\n#############"
}

env='stage'
host="https://foo:bar@$env.example.com"

verify "$host/testing"
verify "$host/foobar" '-H "User-Agent: iphone"'
verify "$host/beepboop" '-H "X-Custom-Foo: true" -H "X-Custom-Bar: false"'

#!/usr/bin/env bash

set -eo pipefail

cd /app

echo '********** configure nginx (as rig test overwites Dockerfile CMD) **********'

/rig_exec python /app/template.py nginx.conf.j2 /nginx.conf true  # †
sed -i 's/^daemon off;/daemon on;/g' /nginx.conf
nginx -c /nginx.conf

# †
# uses python with mustache template to dynamically generate conf 
# so we can switch into nginx location block a static asset behaviour
#
# root /app/fixtures;
#
# this means we can curl endpoints like we would in production
# but they'll not hit our actual upstream/backends, it'll hit a local fixture file

echo '********** nginx tests **********'

function test_curl {
	response=$(curl -sI http://127.0.0.1:64821/$1 | head -n 1)

  if ! [[ $response =~ '200 OK' ]]; then
    printf "failed route: %s\n" $1
    exit 1
  fi
}

test_curl "claudiakoerner/truck-drives-into-bastile-day-crowd-in-nice-france"

#!/bin/bash
#
# Dependencies:
# brew install jq
#
# Example:
# /bin/bash ./results.sh <cert_path> <component_name> <cosmos_user>
#
# Description:
# Grabs list of running instances for specified BBC Cosmos component (TEST environment)
# SCP's known log locations from remote to new local directory

# Enable a form of 'strict mode' for Bash
set -euo pipefail
IFS=$'\n\t'

# Define our expected variables up front
cert=${1:-}
component=${2:-}
user=${3:-}
api="https://api.live.bbc.co.uk/cosmos/env/test/component/$component/instances"

if [ "$#" -ne 3 ]; then
  cat <<EOF

Please check the arguments are provided correctly:
  1. cert path (pem)
  2. component name
  3. cosmos user

If you have any curl/cert issues try:
  brew install curl --with-openssl

If you have any parsing issues try:
  brew install jq

If you have any issues with SCP then
make sure you've given your user SSH access via Cosmos.
This is something I'd like to automate via this script in future.
EOF

  exit 1
fi

instances=($(curl --silent --insecure --cert $cert $api | jq --raw-output .[].private_ip_address))

logdir=$(mktemp -d logs.XXXX)

for ip in "${instances[@]}"
do
  scp -v -r "$user@$ip,eu-west-1:/var/log/component/app.log" "./$logdir/$ip.log" &
done

wait

echo "Complete"

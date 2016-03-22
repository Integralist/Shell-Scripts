#!/bin/bash
#
# Dependencies:
# brew install jq
#
# Example:
# /bin/bash ./results.sh <cert_path> <component_name> <cosmos_user>
#
# Description:
# Grabs list of running instances for specified Cosmos component (TEST environment)
# SCP's known log locations from remote to new local directory

# Enable a form of 'strict mode' for Bash
set -euo pipefail
IFS=$'\n\t'

# Define our expected variables up front
cert=${1:-}
component=${2:-}
user=${3:-}
api="https://api.live.bbc.co.uk/cosmos/env/test/component/$component"

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

logdir=$(mktemp -d logs.XXXX)

data=($(curl --silent --cert $cert "$api/instances" | jq --raw-output ".[] | .id,.private_ip_address"))
data_len=$((${#data[@]} / 2)) # we know we'll always have a pair of data -> <id>,<ip>

for ((n = 0; n < $data_len; n++))
do
  ssh_success=false
  valid="current"

  id=$(($n * 2))
  ip=$(($id + 1))

  instance_id=${data[$id]}
  instance_ip=${data[$ip]}

  response=$(curl --silent \
                  --cert $cert \
                  --header "Content-Type: application/json" \
                  --request POST \
                  --data "{\"instance_id\":\"$instance_id\"}" \
                  "$api/logins/create")

  checkpoint_id=$(echo $response | jq --raw-output .url | cut -d '/' -f 7)

  until $ssh_success
  do
    status=$(curl --silent --cert $cert "$api/login/$checkpoint_id" | jq --raw-output .status)

    if [ "$status" = "$valid" ]; then
      ssh_success=true
      printf "\n"
      echo "OK we've got SSH access to instance number $(($n + 1)): $instance_id ($instance_ip)"
      printf "\n"
    else
      echo "Sorry, still waiting access to: $instance_id (status == $status)"
    fi
  done

  scp -r "$user@$instance_ip,eu-west-1:/var/log/component/app.log" "./$logdir/$instance_ip.log" &
done

wait

echo "Complete"

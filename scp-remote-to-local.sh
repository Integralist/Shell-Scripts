#!/bin/bash
#
# Dependencies:
#   brew install jq
#
# Example:
#   /bin/bash ./scp-remote-to-local.sh <cert_path> <component_name> <cosmos_user>
#
# Description:
#   Grabs list of running instances for specified Cosmos component (TEST environment)
#   SCP's known log locations from remote to new local directory

# Enable a form of 'strict mode' for Bash
set -euo pipefail
IFS=$'\n\t'

# Define our expected variables up front
cert=${1:-}
component=${2:-}
user=${3:-}
failed_access=()
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
EOF

  exit 1
fi

logdir=$(mktemp -d "$component.logs.XXXX")

data=($(curl --silent --cert $cert "$api/instances" | jq --raw-output ".[] | .id,.private_ip_address,.launch_time"))
data_len=$((${#data[@]} / 3)) # we know we'll always have a triad of data -> <id>,<ip>,<launch_time>

for ((n = 0; n < $data_len; n++))
do
  ssh_success=false
  failed=false

  # parse array indexes needed to extract data
  id=$(($n * 3))
  ip=$(($id + 1))
  ti=$(($id + 2))

  instance_id=${data[$id]}
  instance_ip=${data[$ip]}
  launch_time=${data[$ti]}

  printf "\n######################################\n"
  printf "\nrequesting ssh access for: $instance_id\n"

  # use cosmos api to generate ssh access token
  response=$(curl --silent \
                  --cert $cert \
                  --header "Content-Type: application/json" \
                  --request POST \
                  --data "{\"instance_id\":\"$instance_id\"}" \
                  "$api/logins/create")

  # parse token from api response
  checkpoint_id=$(echo $response | jq --raw-output .url | cut -d '/' -f 7)

  until $ssh_success
  do
    status=$(curl --silent --cert $cert "$api/login/$checkpoint_id" | jq --raw-output .status)

    if [ "$status" = "current" ]; then
      ssh_success=true
      printf "\n\nssh access granted for instance $(($n + 1)): $instance_id ($instance_ip)\n\n"
    elif [ "$status" = "failed" ]; then
      failed_access+=("$instance_id - $instance_ip - $launch_time")
      failed=true
      break
    else
      echo -ne "status == $status               "\\r
    fi
  done

  if [ "$failed" = true ]; then
    continue
  else
    scp -r "$user@$instance_ip,eu-west-1:/var/log/component/app.log" "./$logdir/$launch_time-$instance_ip.log"
  fi
done

# removed 'wait' command here and '&' backgrounding of scp process
# as stdout feedback was getting interleaved and really confusing

printf "\n######################################\n\n"
echo "all logs copied successfully"

failed_len=$(echo ${#failed_access[@]})
if [ "$failed_len" -gt 0 ]; then
  printf "\n######################################\n\n"
  echo "there were '$failed_len' failed ssh attempts"

  for i in "${failed_access[@]}"
  do
    printf "\t - $i\n"
  done
fi

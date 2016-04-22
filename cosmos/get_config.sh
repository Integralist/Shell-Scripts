#!/bin/bash
#
# Example:
#   /bin/bash ./get_config.sh <cosmos_user> [cert_path]
#
# Dependencies:
#   brew install jq
#
# Description:
#   Connects to first available EC2 instance and copies down a configuration file

component=dev-news-jenkins-master
user=${1:-}
cert=${2:-$DEV_CERT_PEM}
env=live
local_config=$(echo $(git rev-parse --show-toplevel)/master/cosmos-config.json)
valid=current
api="https://api.live.bbc.co.uk/cosmos/env/$env/component/$component"

if [ $# -lt 1 ]; then
  cat <<EOF

Please double check the arguments are provided correctly (and in this order):
  1. cosmos user
  2. dev cert path (optional - default: \$DEV_CERT_PEM)

If you have any curl/cert issues try:
  brew install curl --with-openssl
EOF

  exit 1
fi

# check the jq dependency is available
type jq >/dev/null 2>&1 || { printf >&2 "\nThe jq dependency is missing. Please first run 'brew install jq'\n"; exit 1; }

instances=($(curl --silent --cert $cert "$api/instances" | jq --raw-output ".[] | .id,.private_ip_address"))
num_of_instances=$((${#instances[@]} / 2)) # we know the data arrives in a pair: <id>,<ip>

ssh_success=false

instance_id=${instances[0]}
instance_ip=${instances[1]}

printf "\nrequesting ssh access for: $instance_id\n\n"

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

  if [ "$status" = "$valid" ]; then
    ssh_success=true
    printf "\n\nssh access granted for instance: $instance_id ($instance_ip)\n\n"
  else
    echo -ne "status == $status               "\\r
  fi
done

ssh -t "$instance_ip,eu-west-1" "sudo cp /etc/bake-scripts/config.json /tmp"
ssh -t "$instance_ip,eu-west-1" "sudo chown -R $user:$user /tmp/config.json"
scp -r "$user@$instance_ip,eu-west-1:/tmp/config.json" "$local_config"
ssh -t "$instance_ip,eu-west-1" "sudo rm /tmp/config.json"

printf "\nCosmos configuration file copied successfully to: \n\n\t$local_config\n"

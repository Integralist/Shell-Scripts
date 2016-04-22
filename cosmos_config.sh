#!/bin/bash
#
# Example:
#   /bin/bash ./cosmos_config.sh <component_name> <cosmos_user> [environment] [cert_path]
#
# Dependencies:
#   brew install jq
#
# Description:
#   Connects to first available EC2 instance and copies down a configuration file

component=${1:-}
user=${2:-}
env=${3:-live}
cert=${4:-$DEV_CERT_PEM}
local_config=./cosmos-config.json
valid=current
api="https://api.live.bbc.co.uk/cosmos/env/$env/component/$component"

if [ $# -lt 2 ]; then
  cat <<EOF

Please double check the arguments are provided correctly (and in this order):
  1. component name
  2. cosmos user
  3. environment (optional - default: live)
  4. dev cert path (optional - default: \$DEV_CERT_PEM)

If you have any curl/cert issues try:
  brew install curl --with-openssl
EOF

  exit 1
fi

instances=($(curl --silent --cert $cert "$api/instances" | jq --raw-output ".[] | .id,.private_ip_address"))
num_of_instances=$((${#instances[@]} / 2)) # we know the data arrives in a pair: <id>,<ip>

ssh_success=false

instance_id=${instances[0]}
instance_ip=${instances[1]}

printf "\n######################################\n"
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
    printf "\n"
    echo "ssh access granted for instance: $instance_id ($instance_ip)"
    printf "\n"
  else
    echo -ne "status == $status               "\\r
  fi
done

ssh -t "$instance_ip,eu-west-1" "sudo cp /etc/bake-scripts/config.json /tmp"
ssh -t "$instance_ip,eu-west-1" "sudo chown -R $user:$user /tmp/config.json"
scp -r "$user@$instance_ip,eu-west-1:/tmp/config.json" "$local_config"
ssh -t "$instance_ip,eu-west-1" "sudo rm /tmp/config.json"

printf "\n######################################\n\n"
echo "Cosmos configuration file copied successfully to $local_config"

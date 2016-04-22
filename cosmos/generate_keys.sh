#!/bin/bash
#
# Example:
#   /bin/bash ./generate_keys.sh
#
# Dependencies:
#   brew install jq
#
# Description:
#   Opens the Cosmos JSON file and extracts the private/public key and places them into actual files

root=$(git rev-parse --show-toplevel)
config="$root/master/cosmos-config.json"

# check the jq dependency is available
type jq >/dev/null 2>&1 || { printf >&2 "\nThe jq dependency is missing. Please first run 'brew install jq'\n"; exit 1; }

if [ ! -f "$config" ]; then
  printf "\nSorry, this script needs access to $config - please run 'get_config.sh' script first\n"
  exit 1
fi

function strip_newlines() {
  local config=$1
  local key=$2
  cat $config | jq --raw-output "$key" | sed 's/$/\\n/' | tr -d '\n'
}

private=$(strip_newlines $config ".secure_configuration.git_ssh_private_key")
public=$(cat $config | jq --raw-output ".secure_configuration.git_ssh_public_key")
backup=$(cat $config | jq --raw-output ".secure_configuration.backup_encryption_key_20150608")

# we need to remove a stray \n at the end of the ouput in each variable; hence ${VAR::-2}
echo "${private::-2}" > $root/master/private.key
echo $public > $root/master/public.key
echo $backup > $root/master/backup_encryption_key

printf "\nThe private, public and backup key files have been successfully generated:\n"

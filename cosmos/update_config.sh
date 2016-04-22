#!/bin/bash
#
# Dependencies:
#   - get_config.sh is a script that pulls down the cosmos configuration
#   - generate_keys.sh is a script that extracts keys from the cosmos configuration
#   - whitelist.txt is a csv of user emails indicating who is able to access this component (e.g. "foo@bbc.co.uk,bar@bbc.co.uk,baz@bbc.co.uk")(
#
# Example:
#   /bin/bash ./update_config.sh [cert_path]
#
# Description:
#   Updates the Cosmos configuration for the News Jenkins Master component

cert=${1:-$DEV_CERT_PEM}
endpoint=https://api.live.bbc.co.uk/cosmos/env/live/component/dev-news-jenkins-master/configuration

root=$(git rev-parse --show-toplevel)
local_config=$(echo $(git rev-parse --show-toplevel)/master/cosmos-config.json)

if [ ! -f "$root/master/private.key" ] || [ ! -f "$root/master/public.key" ] || [ ! -f "$root/master/backup_encryption_key" ]; then
  printf "\nSorry, the expected private/public/backup keys are missing - so we need to run the 'get_config.sh' script now...\n"
  printf "\nBut first, please tell me your Cosmos username:\n\n"
  read username
  if [ -z "$username" ] ; then
    printf "\nSorry, no username was provided so I'm going to quit now\n"
    exit 1
  fi
  printf "\nThanks. I'm going to attempt to retrieve the existing cosmos config now...\n\n"
  $(bash $root/master/get_config.sh $username) 1>/dev/null 2>&1
  printf "\nOK, I've got the config so I'm now going to attempt to extract the keys...\n\n"
  $(bash $root/master/generate_keys.sh) 1>/dev/null 2>&1
  printf "Extraction is done...\n\n"
  ls -l master/ | grep -E 'private|public|backup'
  printf "\n"
fi

curl $endpoint --cert $cert --header 'Content-Type: application/json' --request PUT --data-binary @- <<BODY
[
    {
        "key": "git_ssh_private_key",
        "value": "$(cat $root/master/private.key)",
        "secure": true
    },
    {
        "key": "git_ssh_public_key",
        "value": "$(cat $root/master/public.key)",
        "secure": true
    },
    {
        "key": "administrators",
        "value": "foobar@bbc.co.uk"
    },
    {
        "key": "backup_encryption_key_20160421",
        "value": "$(cat $root/master/backup_encryption_key)",
        "secure": true
    },
    {
        "key": "backup_s3_bucket",
        "value": "foobar"
    },
    {
        "key": "backup_s3_path",
        "value": "/jenkins-backups/"
    },
    {
        "key": "cloudwatch_log_group_name",
        "value": "foobar"
    },
    {
      "key": "developers",
      "value": "$(cat $root/master/whitelist.txt | tr '\n' ',' | rev | cut -c 2- | rev)"
    }
]
BODY

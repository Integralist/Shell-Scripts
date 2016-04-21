#!/bin/bash
#
# Dependencies:
#   whitelist.txt is a csv of user emails
#   indicating who is able to access this component
#   e.g. "foo@bbc.co.uk,bar@bbc.co.uk,baz@bbc.co.uk"
#
# Example:
#   /bin/bash ./configuration.sh [cert_path]
#
# Description:
#   Updates a component's configuration via a REST API (BBC specific example script)

cert=${1:-$DEV_CERT_PEM}
endpoint=https://foo.bbc.co.uk/env/int/component/bar/configuration

curl endpoint \
--cert $cert \
--header 'Content-Type: application/json' \
--request PUT \
--data-binary @- <<BODY
[
    {
        "key": "git_ssh_private_key",
        "value": "$(cat private.key)",
        "secure": true
    },
    {
        "key": "git_ssh_public_key",
        "value": "$(cat public.key)",
        "secure": true
    },
    {
        "key": "administrators",
        "value": "some.person@bbc.co.uk"
    },
    {
        "key": "backup_encryption_key_20160421",
        "value": "xxxx",
        "secure":true
    },
    {
        "key": "backup_s3_bucket",
        "value": "live-component-master-main-s3bucket-xxxx"
    },
    {
        "key": "backup_s3_path",
        "value": "/component-backups/"
    },
    {
      "key: "developers",
      "value": "$(cat master/whitelist.txt | tr '\n' ',' | rev | cut -c 2- | rev)"
    }
]
BODY

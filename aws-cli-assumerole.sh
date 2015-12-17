#! /bin/bash
#
# Dependencies:
#   brew install jq
#
# Execute:
#   source aws-cli-assumerole.sh
#
# Setup:
# chmod +x ./aws-cli-assumerole.sh
# cp ./aws-cli-assumerole.sh /usr/local/bin

unset AWS_SESSION_TOKEN
export AWS_ACCESS_KEY_ID=<user_access_key>
export AWS_SECRET_ACCESS_KEY=<user_secret_key>

temp_role=$(aws sts assume-role \
                    --role-arn "arn:aws:iam::<aws_account_number>:role/<role_name>" \
                    --role-session-name "<some_session_name>")

export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq .Credentials.SessionToken)

env | grep -i AWS_

#!/bin/bash
#
# Example:
#   /bin/bash ./git-tag-compared-to-release.sh
#
# Description:
#   This script isn't intended to be run standalone but within a Jenkins CI shell execution block
#   It gets a release number from an external service (you'd have to one, otherwise this script is useless to you)
#   It then checks the current git tag to see if it's larger than the 'release' number
#   If it is then it'll go ahead and build a new 'release'
#   It's purpose is to prevent builds occuring for simple README style changes within a GitHub repository

echo 0 > status

latest_release=$(curl \
                    --cert /etc/pki/tls/certs/client.crt \
                    --key /etc/pki/tls/private/client.key \
                    --header 'Content-Type: application/json' \
                    --silent \
                    https://my.api.com/component/foo/releases | \
                 grep -Eo '"version": "[[:digit:]]+' | \
                 cut -d : -f 2 | \
                 cut -d '"' -f 2 | \
                 head -n 1)

tag=$(git tag | tail -n 1)

if [ $tag -le $latest_release ]; then
  echo 1 > status
  echo "The latest tag ($tag) is less than, or equal to, the latest release ($latest_release) so no point in building a new release"
  exit
fi

echo "DO STUFF"

# In another Jenkins shell block...

if [ $(cat status) -eq 1 ]; then
  exit
fi

echo "OTHERWISE DO STUFF"

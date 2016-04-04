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

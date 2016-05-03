if [ $(cat status) -eq 1 ]; then
  exit
fi

printf "\nPull Golang Container 1.6.2\n\n"

	CONTAINER_WS=/gopath/src/github.com/bbc/mozart-requester/src

	docker pull golang:1.6.2

printf "\nInstall Dependencies and Run Tests\n\n"

	docker run --rm=true -v $WORKSPACE/src:$CONTAINER_WS -e "GOPATH=/gopath" -e "APP_ENV=test" -w $CONTAINER_WS golang:1.6.2 \
	  sh -c 'go get github.com/Masterminds/glide && /gopath/bin/glide install && go test $(/gopath/bin/glide novendor)'
      
printf "\nCompile Application Binary\n\n"

	docker run --rm=true -v $WORKSPACE/src:$CONTAINER_WS -e "GOPATH=/gopath" -w $CONTAINER_WS golang:1.6.2 \
	  sh -c 'CGO_ENABLED=0 go build -a --installsuffix cgo --ldflags=\"-s\" -o mozart-requester'

printf "\nMove Binary to SOURCES\n\n"

	mv src/mozart-requester SOURCES
    
printf "\nPull MBT Container\n\n"

	docker pull registry.news.api.bbci.co.uk/mbt-build

printf "\nBuild RPM\n\n"

	cosmos-build --os=centos7 -s docker -i registry.news.api.bbci.co.uk/mbt-build

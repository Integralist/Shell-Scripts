printf "\nPull Golang Container 1.6.2\n\n"

	CONTAINER_WS=/gopath/src/github.com/integralsit/go-app/src

	docker pull golang:1.6.2

printf "\nInstall Dependencies\n\n"

	docker run --rm=true -v $WORKSPACE/src:$CONTAINER_WS -e "GOPATH=/gopath" -w $CONTAINER_WS golang:1.6.2 \
	  sh -c 'go get github.com/Masterminds/glide && /gopath/bin/glide install'
  
printf "\nCompile Application Binary\n\n"

	docker run --rm=true -v $WORKSPACE/src:$CONTAINER_WS -e "GOPATH=/gopath" -w $CONTAINER_WS golang:1.6.2 \
	  sh -c 'CGO_ENABLED=0 go build -a --installsuffix cgo --ldflags=\"-s\" -o go-app-binary'

printf "\nMove Binary to SOURCES\n\n"

	mv src/go-app-binary SOURCES

printf "\nPull Custom Build Container\n\n"

	docker pull registry.bbc.co.uk/custom-build

printf "\nBuild RPM\n\n"

	custom-build --os=centos7 -s docker -i registry.bbc.co.uk/custom-build

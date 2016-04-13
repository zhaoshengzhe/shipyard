CGO_ENABLED=0
GOOS=linux
GOARCH=amd64
TAG=${TAG:-latest}
COMMIT=`git rev-parse --short HEAD`

all: build media

clean:
	@rm -rf controller/controller

build:
	@cd controller && godep go build -a -tags "netgo static_build" -installsuffix netgo -ldflags "-w -X github.com/shipyard/shipyard/version.GitCommit=$(COMMIT)" .

remote-build:
	@docker build -t shipyard-build -f Dockerfile.build .
	@rm -f ./controller/controller
	@cd controller && docker run --rm -w /go/src/github.com/shipyard/shipyard --entrypoint /bin/bash shipyard-build -c "make build 1>&2 && cd controller && tar -czf - controller" | tar zxf -

media:
	@cd controller/static && bower -s install --allow-root -p | xargs echo > /dev/null

image: media build
	@echo Building Shipyard image $(TAG)
	@cd controller && docker build -t="zhaoshengz/shipyard" .

release: build image
	@docker push shipyard/shipyard:$(TAG)

test: clean 
	@godep go test -v ./...

testrun:
	@cd controller 	&& ./controller --debug server --rethinkdb-addr=${IP}:28015 -d tcp://192.168.59.103:2376

.PHONY: all build clean media image test release

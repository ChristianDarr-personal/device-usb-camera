.PHONY: build docker test clean prepare update

#GOOS=linux

GO=CGO_ENABLED=0 go
GOCGO=CGO_ENABLED=1 go

MICROSERVICES=cmd/device-usb-camera
.PHONY: $(MICROSERVICES)

VERSION=$(shell cat ./VERSION 2>/dev/null || echo 0.0.0)

GIT_SHA=$(shell git rev-parse HEAD)
GOFLAGS=-ldflags "-X github.com/edgexfoundry/device-usb-camera.Version=$(VERSION)"

ARCH=$(shell uname -m)

build: $(MICROSERVICES)

cmd/device-usb-camera:
	$(GOCGO) build $(GOFLAGS) -o $@ ./cmd

docker:
	docker build . \
		--label "git_sha=$(GIT_SHA)" \
		-t edgexfoundry/device-usb-camera:$(GIT_SHA) \
		-t edgexfoundry/device-usb-camera:$(VERSION)-dev

tidy:
	go mod tidy

unittest:
	$(GO) test ./... -coverprofile=coverage.out ./...

lint:
	@which golangci-lint >/dev/null || echo "WARNING: go linter not installed. To install, run\n  curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b \$$(go env GOPATH)/bin v1.42.1"
	@if [ "z${ARCH}" = "zx86_64" ] && which golangci-lint >/dev/null ; then golangci-lint run --config .golangci.yml ; else echo "WARNING: Linting skipped (not on x86_64 or linter not installed)"; fi

test: unittest lint
	$(GO) vet ./...
	gofmt -l $$(find . -type f -name '*.go'| grep -v "/vendor/")
	[ "`gofmt -l $$(find . -type f -name '*.go'| grep -v "/vendor/")`" = "" ]
	./bin/test-attribution-txt.sh

coveragehtml:
	go tool cover -html=coverage.out -o coverage.html

format:
	gofmt -l $$(find . -type f -name '*.go'| grep -v "/vendor/")
	[ "`gofmt -l $$(find . -type f -name '*.go'| grep -v "/vendor/")`" = "" ]

update:
	$(GO) mod download

clean:
	rm -f $(MICROSERVICES)

vendor:
	$(GO) mod vendor

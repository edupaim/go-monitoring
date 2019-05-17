APPLICATION_NAME := $(shell grep "const ApplicationName " version.go | sed -E 's/.*"(.+)"$$/\1/')
BIN_NAME=${APPLICATION_NAME}

# grep the version from the mix file
BASE_VERSION := $(shell grep "const Version " version.go | sed -E 's/.*"(.+)"$$/\1/')
VERSION="${BASE_VERSION}.$(shell date +%s | head -c 9)"

GIT_COMMIT=$(shell git rev-parse HEAD)
GIT_DIRTY=$(shell test -n "`git status --porcelain`" && echo "+CHANGES" || true)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

default: help

build: ## Build project for development
	@echo "building ${BIN_NAME} ${BASE_VERSION}"
	@echo "GOPATH=${GOPATH}"
	go build -ldflags "-X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY} -X main.VersionPrerelease=DEV" -o bin/${BIN_NAME} ./

build-native-production: ## Build project for native production
	@echo "building ${BIN_NAME} ${BASE_VERSION}"
	@echo "GOPATH=${GOPATH}"
	go build -ldflags "-X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY}" -o bin/${BIN_NAME} ./

build-production: ## Build project for all plataforms production
	@echo "building ${BIN_NAME} ${BASE_VERSION}"
	@echo "GOPATH=${GOPATH}"
	GOOS=linux GOARCH=386 go build -ldflags "-X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY}" -o bin/${BIN_NAME}32 ./
	GOOS=linux GOARCH=amd64 go build -ldflags "-X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY}" -o bin/${BIN_NAME}64 ./
	GOOS=linux GOARCH=arm go build -ldflags "-X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY}" -o bin/${BIN_NAME}-arm32 ./
	GOOS=linux GOARCH=arm64 go build -ldflags "-X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY}" -o bin/${BIN_NAME}-arm64 ./
	GOOS=windows GOARCH=386 go build -ldflags "-X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY}" -o bin/${BIN_NAME}32.exe ./
	GOOS=windows GOARCH=amd64 go build -ldflags "-X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY}" -o bin/${BIN_NAME}64.exe ./

dist: build-production ## Pack project for all plataforms production
	@echo "building dist files for Windows"
	cd bin && mv ${BIN_NAME}32.exe ${BIN_NAME}.exe
	cd bin && zip ${BIN_NAME}_win32.zip ${BIN_NAME}.exe
	cd bin && mv ${BIN_NAME}.exe ${BIN_NAME}32.exe
	cd bin && mv ${BIN_NAME}64.exe ${BIN_NAME}.exe
	cd bin && zip ${BIN_NAME}_win64.zip ${BIN_NAME}.exe
	cd bin && mv ${BIN_NAME}.exe ${BIN_NAME}64.exe
	@echo "building dist files for Linux"
	cd bin && mv ${BIN_NAME}32 ${BIN_NAME}
	cd bin && tar -zcvf ${BIN_NAME}_linux32.tar.gz ${BIN_NAME}
	cd bin && mv ${BIN_NAME} ${BIN_NAME}32
	cd bin && mv ${BIN_NAME}64 ${BIN_NAME}
	cd bin && tar -zcvf ${BIN_NAME}_linux64.tar.gz ${BIN_NAME}
	cd bin && mv ${BIN_NAME} ${BIN_NAME}64
	@echo "building dist files for Linux (ARM)"
	cd bin && mv ${BIN_NAME}-arm32 ${BIN_NAME}
	cd bin && tar -zcvf ${BIN_NAME}_linux_arm32.tar.gz ${BIN_NAME}
	cd bin && mv ${BIN_NAME} ${BIN_NAME}-arm32
	cd bin && mv ${BIN_NAME}-arm64 ${BIN_NAME}
	cd bin && tar -zcvf ${BIN_NAME}_linux_arm64.tar.gz ${BIN_NAME}
	cd bin && mv ${BIN_NAME} ${BIN_NAME}-arm64

get-deps: ## Install projects dependecies with Glide
	glide install

up-deps: ## Update projects dependecies with Glide
	glide up

docker-build: build-native-production ## Build docker image
	docker build -t ${APPLICATION_NAME}:${BASE_VERSION} ./

release: docker-build ## docker-tag docker-push ## Build, tag and push docker image

clean: ## Clean build project
	@test ! -e bin/${BIN_NAME} || rm bin/${BIN_NAME}

run-test:  ## Run project tests
	mkdir -p ./test/cover
#	go test -race -coverpkg=./... -coverprofile=./test/cover/cover.out
	go test -coverpkg=./... -coverprofile=./test/cover/cover.out
	go tool cover -html=./test/cover/cover.out -o ./test/cover/cover.html

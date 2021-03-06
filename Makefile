# Copyright SecureKey Technologies Inc.
#
# SPDX-License-Identifier: Apache-2.0


HTTP_SERVER_PATH       = cmd/http-server
GOBIN_PATH             = $(abspath .)/build/bin

# GO version
ALPINE_VER ?= 3.10
GO_TAGS    ?=
GO_VER     ?= 1.13.1

# Namespace for the images
DOCKER_OUTPUT_NS         ?= docker.pkg.github.com
WASM_IMAGE_NAME          ?= trustbloc/edge-agent


.PHONY: all
all: clean checks unit-test unit-test-wasm

.PHONY: depend
depend:
	@mkdir -p ./build/bin
	GO111MODULE=off GOBIN=$(GOBIN_PATH) go get github.com/agnivade/wasmbrowsertest

.PHONY: checks
checks: license lint

.PHONY: lint
lint:
	@scripts/check_lint.sh

.PHONY: license
license:
	@scripts/check_license.sh

.PHONY: unit-test
unit-test:
	@scripts/check_unit.sh

.PHONY: unit-test-wasm
unit-test-wasm: export GOBIN=$(GOBIN_PATH)
unit-test-wasm: depend
	@scripts/check_unit_wasm.sh

.PHONY: agent-wasm
agent-wasm:
	@scripts/build_agent_wasm.sh ${AGENT_NAME}

.PHONY: issuer-agent-wasm
issuer-agent-wasm:
	AGENT_NAME="issuer" make agent-wasm

.PHONY: user-agent-wasm
user-agent-wasm:
	AGENT_NAME="user" make agent-wasm

.PHONY: rp-agent-wasm
rp-agent-wasm:
	AGENT_NAME="rp" make agent-wasm

.PHONY: http-server
http-server:
	@echo "Building http-server"
	@mkdir -p ./build/bin/wasm
	@cd ${HTTP_SERVER_PATH} && go build -o ../../build/bin/http-server main.go

.PHONY: issuer-agent-wasm-docker
issuer-agent-wasm-docker:
	AGENT_NAME="issuer" make agent-wasm-docker

.PHONY: user-agent-wasm-docker
user-agent-wasm-docker:
	AGENT_NAME="user" make agent-wasm-docker

.PHONY: rp-agent-wasm-docker
rp-agent-wasm-docker:
	AGENT_NAME="rp" make agent-wasm-docker

.PHONY: agent-wasm-docker
agent-wasm-docker: clean
	@echo "Building issuer agent wasm docker image"
	@docker build -f ./images/agent-wasm/Dockerfile --no-cache -t $(DOCKER_OUTPUT_NS)/$(WASM_IMAGE_NAME)/${AGENT_NAME}-agent-wasm:latest \
	--build-arg GO_VER=$(GO_VER) \
	--build-arg ALPINE_VER=$(ALPINE_VER) \
	--build-arg GO_TAGS=$(GO_TAGS) \
	--build-arg NAME=${AGENT_NAME} .

.PHONY: clean
clean: clean-build

.PHONY: clean-build
clean-build:
	@rm -Rf ./build
	@rm -Rf ./cmd/issuer-agent/web/dist
	@rm -Rf ./cmd/user-agent/web/dist
	@rm -Rf ./cmd/rp-agent/web/dist
	@rm -Rf ./cmd/issuer-agent/web/node_modules
	@rm -Rf ./cmd/user-agent/web/node_modules
	@rm -Rf ./cmd/rp-agent/web/node_modules

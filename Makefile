UNIT_TEST_TAGS=

SDK_MIN_GO_VERSION ?= 1.22

EACHMODULE_FAILFAST ?= true
EACHMODULE_FAILFAST_FLAG=-fail-fast=${EACHMODULE_FAILFAST}

EACHMODULE_CONCURRENCY ?= 1
EACHMODULE_CONCURRENCY_FLAG=-c ${EACHMODULE_CONCURRENCY}

EACHMODULE_SKIP ?=
EACHMODULE_SKIP_FLAG=-skip="${EACHMODULE_SKIP}"

EACHMODULE_FLAGS=${EACHMODULE_CONCURRENCY_FLAG} ${EACHMODULE_FAILFAST_FLAG} ${EACHMODULE_SKIP_FLAG}

REPOTOOLS_VERSION ?= latest
REPOTOOLS_MODULE = github.com/awslabs/aws-go-multi-module-repository-tools
REPOTOOLS_CMD_UPDATE_REQUIRES = ${REPOTOOLS_MODULE}/cmd/updaterequires@${REPOTOOLS_VERSION}
REPOTOOLS_CMD_UPDATE_MODULE_METADATA = ${REPOTOOLS_MODULE}/cmd/updatemodulemeta@${REPOTOOLS_VERSION}

.PHONY: all
all: generate unit

###################
# Code Generation #
###################
.PHONY: generate smithy-go-publish-local smithy-generate update-requires update-module-metadata min-go-version-% tidy-modules-%

generate: smithy-go-publish-local smithy-generate update-requires update-module-metadata min-go-version-. tidy-modules-.

smithy-go-publish-local:
	rm -rf /tmp/smithy-go-local
	git clone https://github.com/aws/smithy-go /tmp/smithy-go-local
	make -C /tmp/smithy-go-local smithy-clean smithy-publish-local

smithy-generate:
	cd codegen && ./gradlew clean build -Plog-tests && ./gradlew clean

update-requires:
	go run ${REPOTOOLS_CMD_UPDATE_REQUIRES}

update-module-metadata:
	go run ${REPOTOOLS_CMD_UPDATE_MODULE_METADATA}

min-go-version-%:
	cd ./internal/repotools/cmd/eachmodule \
		&& go run . -p $(subst _,/,$(subst min-go-version-,,$@)) ${EACHMODULE_FLAGS} \
		"go mod edit -go=${SDK_MIN_GO_VERSION}"


tidy-modules-%:
	@# tidy command that uses the pattern to define the root path that the
	@# module testing will start from. Strips off the "tidy-modules-" and
	@# replaces all "_" with "/".
	@#
	@# e.g. tidy-modules-internal_protocoltest
	cd ./internal/repotools/cmd/eachmodule \
		&& go run . -p $(subst _,/,$(subst tidy-modules-,,$@)) ${EACHMODULE_FLAGS} \
		"go mod tidy"

################
# Unit Testing #
################
.PHONY: unit unit-race unit-test unit-race-test unit-race-modules-% unit-modules-% build build-modules-% \
go-build-modules-% test test-race-modules-% test-modules-%

test: test-modules-.

test-modules-%:
	@# Test command that uses the pattern to define the root path that the
	@# module testing will start from. Strips off the "test-modules-" and
	@# replaces all "_" with "/".
	@#
	@# e.g. test-modules-internal_protocoltest
	cd ./internal/repotools/cmd/eachmodule \
		&& go run . -p $(subst _,/,$(subst test-modules-,,$@)) ${EACHMODULE_FLAGS} \
		"go test -timeout=2m ${UNIT_TEST_TAGS} -race ./..."

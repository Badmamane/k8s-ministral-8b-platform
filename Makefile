SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

PROJECT  := k8s-ministral-8b
ENV      ?= dev
REGION   ?= us-east-1
LIVE_DIR := live/$(ENV)
TG       := terragrunt --working-dir $(LIVE_DIR) --non-interactive

.PHONY: help fmt lint validate plan apply destroy admit-runner test orphan-check

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

fmt: ## Format Terraform and Terragrunt files
	terraform fmt -recursive modules
	terragrunt hcl fmt --working-dir live

lint: ## Format check, tflint, checkov
	terraform fmt -check -recursive modules
	terragrunt hcl fmt --check --working-dir live
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"
	checkov --directory modules --framework terraform --quiet --compact

validate: ## terragrunt run --all validate (mock outputs)
	$(TG) run --all validate

plan: ## terragrunt run --all plan
	$(TG) run --all plan

apply: ## Create the whole environment (CREATE=1 required)
	@[ "$(CREATE)" = "1" ] || { echo "refusing: set CREATE=1 to apply"; exit 1; }
	$(TG) run --all apply

destroy: ## Destroy every unit in reverse dependency order (DESTROY=1 required)
	@[ "$(DESTROY)" = "1" ] || { echo "refusing: set DESTROY=1 to destroy"; exit 1; }
	$(TG) run --all destroy

admit-runner: ## Add RUNNER_CIDR to the cluster API endpoint before a destroy from CI
	terragrunt --working-dir $(LIVE_DIR)/eks --non-interactive apply

test: ## End-to-end smoke tests against a running environment
	./tests/run.sh

orphan-check: ## Fail if resources tagged Project=$(PROJECT) remain outside the bootstrap stack
	PROJECT=$(PROJECT) AWS_REGION=$(REGION) ENV=$(ENV) ./scripts/orphan-check.sh

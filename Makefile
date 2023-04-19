#  Copyright (c) University College London Hospitals NHS Foundation Trust
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
.PHONY: help

SHELL:=/bin/bash
MAKEFILE_FULLPATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR := $(dir $(MAKEFILE_FULLPATH))

target_title = @echo -e "\n\e[34m»»» 🌺 \e[96m$(1)\e[0m..."

define terragrunt  # Arguments: <command>, <folder name>
    $(call target_title, "Running: terragrunt $(1) on $(2)") \
	&& cd ${MAKEFILE_DIR}/$(2) \
	&& terragrunt run-all $(1) \
		--terragrunt-include-external-dependencies \
		--terragrunt-non-interactive \
		--terragrunt-exclude-dir ${MAKEFILE_DIR}/auth
endef

all: az-login ## Deploy everything
	$(call terragrunt,apply,.)

help: ## Show this help
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m|%s\n", $$1, $$2}' \
        | column -t -s '|'
	@echo

lint: ## Call pre-commit hooks to lint files & check for headers
	$(call target_title, "Linting") \
	&& pre-commit run --all-files

az-login: ## Check logged in/log into azure with a service principal
	$(call target_title, "Log-in to Azure") \
	&& cd ${MAKEFILE_DIR}/scripts && ./az_login.sh

auth: az-login ## Create auth app for deployments
	$(call target_title, "Creating auth app") \
	&& cd ${MAKEFILE_DIR}/auth \
	&& terragrunt apply \
	&& printf "\n🌺 Below are the credentials for your auth app:\033[36m\n\n" \
	&& terraform output -json \
	  | jq -r 'with_entries(.value |= .value) | to_entries[] | "\(.key +": "+ .value)"'

infrastructure: az-login ## Deploy all infrastructure
	$(call terragrunt,apply,infrastructure)

infrastructure-core: az-login ## Deploy core infrastructure
	$(call terragrunt,apply,infrastructure/core)

infrastructure-transform: az-login ## Deploy transform infrastructure
	$(call terragrunt,apply,infrastructure/transform)

infrastructure-serve: az-login ## Deploy serve infrastructure
	$(call terragrunt,apply,infrastructure/serve)

test: infrastructure test-pipelines apps destroy  ## Test by deploy->destroy

test-pipelines:
	$(call target_title, "Test Transform Pipelines") \
	&& ${MAKEFILE_DIR}/transform/run_pipelines.sh

test-transform: infrastructure-transform test-pipelines destroy  ## Test transform deploy->destroy

test-serve: infrastructure-serve destroy  ## Test serve deploy->destroy

test-apps: apps destroy  ## Test apps deploy->destroy

transform-artifacts: az-login ## Build transform artifacts
	${MAKEFILE_DIR}/scripts/pipeline_repo_checkout.sh \
	&& ${MAKEFILE_DIR}/scripts/build_artifacts.sh

apps: az-login ## Deploy FlowEHR apps
	$(call terragrunt,apply,apps)

destroy: az-login ## Destroy everything
	$(call terragrunt,destroy,.)

destroy-infrastructure: az-login ## Destroy infrastructure
	$(call terragrunt,destroy,infrastructure)

destroy-apps: az-login ## Destroy apps
	$(call terragrunt,destroy,apps)

destroy-core: az-login ## Destroy core infrastructure
	$(call terragrunt,destroy,infrastructure/core)

destroy-transform: az-login ## Destroy transform infrastructure
	$(call terragrunt,destroy,infrastructure/transform)

destroy-serve: az-login ## Destroy serve infrastructure
	$(call terragrunt,destroy,infrastructure/serve)

destroy-no-terraform: az-login ## Destroy all resource groups associated with this deployment
	$(call target_title, "Destroy no terraform") \
	&& . ${MAKEFILE_DIR}/scripts/destroy_no_terraform.sh

clean: ## Remove all local terraform state
	find ${MAKEFILE_DIR} -type d -name ".terraform" -exec rm -rf "{}" \; || true

tf-reinit: ## Re-init Terraform (use for updating lock files & when backend state changes)
	$(call target_title, "Terraform init") \
	&& cd ${MAKEFILE_DIR} \
	&& terragrunt run-all init -upgrade -migrate-state -input=true

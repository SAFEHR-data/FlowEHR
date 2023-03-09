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
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& cd ${MAKEFILE_DIR}/$(2) \
	&& terragrunt run-all $(1) --terragrunt-include-external-dependencies \
		--terragrunt-non-interactive --terragrunt-exclude-dir ${MAKEFILE_DIR}/ci
endef

all: bootstrap infrastructure apps

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
	&& cd ${MAKEFILE_DIR}/scripts && source load_env.sh && ./az_login.sh

ci-auth: az-login ## Deploy an AAD app with permissions to use for CI builds
	$(call target_title, "Creating CI auth") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& cd ${MAKEFILE_DIR}/ci \
	&& terragrunt run-all apply \
	&& terraform output -json \
	  | jq -r 'with_entries(.value |= .value) | to_entries[] | "\(.key +": "+ .value)"'

bootstrap: az-login ## Boostrap Terraform backend
	$(call target_title, "Bootstrap") \
	&& cd ${MAKEFILE_DIR}/scripts && source load_env.sh && ./bootstrap.sh

bootstrap-destroy: az-login ## Destroy boostrap rg
	$(call target_title, "Destroy Bootstrap Env") \
	&& cd ${MAKEFILE_DIR}/scripts && source load_env.sh && ./bootstrap.sh -d

infrastructure: transform-artifacts bootstrap ## Deploy all infrastructure
	$(call terragrunt,apply,infrastructure)

infrastructure-core: bootstrap ## Deploy core infrastructure
	$(call terragrunt,apply,infrastructure/core)

infrastructure-transform: bootstrap transform-artifacts ## Deploy transform infrastructure
	$(call terragrunt,apply,infrastructure/transform)

transform-artifacts: ## Build transform artifacts
	${MAKEFILE_DIR}/scripts/pipeline_repo_checkout.sh \
	&& ${MAKEFILE_DIR}/scripts/build_artifacts.sh

test-pipelines:
	$(call target_title, "Test Transform Pipelines") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& ${MAKEFILE_DIR}/transform/run_pipelines.sh

infrastructure-serve: bootstrap ## Deploy serve infrastructure
	$(call terragrunt,apply,infrastructure/serve)

test: infrastructure apps destroy-all  ## Test by deploy->destroy

test-transform: infrastructure-transform test-pipelines destroy-all  ## Test transform deploy->destroy

test-serve: infrastructure-serve destroy-all  ## Test transform deploy->destroy

test-without-core-destroy: infrastructure apps destroy-non-core ## Test non-core deploy->destroy destroying core

test-transform-without-core-destroy: infrastructure-transform test-pipelines destroy-non-core  ## Test transform deploy->destroy destroying core

test-serve-without-core-destroy: infrastructure-serve destroy-non-core  ## Test serve deploy->destroy without destroying core

apps: bootstrap ## Deploy FlowEHR apps
	$(call terragrunt,apply,apps)

destroy: az-login ## Destroy all infrastructure
	$(call terragrunt,destroy,.)

destroy-infrastructure: az-login ## Destroy infrastructure
	$(call terragrunt,destroy,infrastructure)

destroy-apps: az-login ## Destroy apps
	$(call terragrunt,destroy,apps)

destroy-core: ## Destroy core infrastructure
	$(call terragrunt,destroy,infrastructure/core)

destroy-transform: ## Destroy transform infrastructure
	$(call terragrunt,destroy,infrastructure/transform)

destroy-serve: ## Destroy serve infrastructure
	$(call terragrunt,destroy,infrastructure/serve)

destroy-non-core: ## Destroy non-core
	$(call target_title, "Destroying non core infrastructure") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& cd ${MAKEFILE_DIR} \
	&& terragrunt run-all destroy \
		--terragrunt-include-external-dependencies \
		--terragrunt-non-interactive \
		--terragrunt-exclude-dir ${MAKEFILE_DIR}/infrastructure/core \
		--terragrunt-exclude-dir ${MAKEFILE_DIR}/ci

destroy-all: destroy bootstrap-destroy  ## Destroy infrastrcture and bootstrap resources

destroy-no-terraform: az-login ## Destroy all resource groups associated with this deployment
	$(call target_title, "Destroy no terraform") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& . ${MAKEFILE_DIR}/scripts/destroy_no_terraform.sh

clean: ## Remove all local terraform state
	find ${MAKEFILE_DIR} -type d -name ".terraform" -exec rm -rf "{}" \; || true

tf-init: az-login ## Init Terraform (use for updating lock files in the case of a conflict)
	$(call target_title, "Terraform init") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& cd ${MAKEFILE_DIR} \
	&& terragrunt run-all init -upgrade

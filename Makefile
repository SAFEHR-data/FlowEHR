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
LINTER_REGEX_INCLUDE?=all # regex to specify which files to include in local linting (defaults to "all")

target_title = @echo -e "\n\e[34m»»» 🌺 \e[96m$(1)\e[0m..."

all: bootstrap deploy-all

help: ## Show this help
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m|%s\n", $$1, $$2}' \
        | column -t -s '|'
	@echo

az-login:  ## Check logged in/log into azure with a service principal 
	$(call target_title, "Log-in to Azure") \
	&& . ${MAKEFILE_DIR}/scripts/az_login.sh

bootstrap: az-login ## Boostrap Terraform backend
	$(call target_title, "Bootstrap") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& . ${MAKEFILE_DIR}/infrastructure/bootstrap.sh

bootstrap-destroy: az-login ## Destroy boostrap rg
	$(call target_title, "Destroy Bootstrap Env") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& . ${MAKEFILE_DIR}/infrastructure/bootstrap.sh -d

deploy-all: az-login  ## Deploy all infrastructure
	$(call target_title, "Deploy All") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& terragrunt run-all apply --terragrunt-working-dir ${MAKEFILE_DIR}/infrastructure --terragrunt-non-interactive

deploy-core: az-login  ## Deploy core infrastructure
	$(call target_title, "Deploy Core") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& terragrunt apply --terragrunt-working-dir ${MAKEFILE_DIR}/infrastructure/core

deploy-transform: az-login  ## Deploy transform infrastructure
	$(call target_title, "Deploy Transform") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& terragrunt apply --terragrunt-working-dir ${MAKEFILE_DIR}/infrastructure/transform

destroy-all: az-login  ## Destroy all infrastructure
	$(call target_title, "Destroy All") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& terragrunt run-all destroy --terragrunt-working-dir ${MAKEFILE_DIR}/infrastructure --terragrunt-non-interactive

test: bootstrap deploy-all destroy-all bootstrap-destroy  ## Test by deploy->destroy

destroy-no-terraform:
	$(call target_title, "Destroy no terraform") \
	&& . ${MAKEFILE_DIR}/scripts/load_env.sh \
	&& . ${MAKEFILE_DIR}/scripts/destroy_no_terraform.sh

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
#  limitations under the License.

locals {
  providers        = read_terragrunt_config("${get_repo_root()}/providers.hcl")
  configuration    = read_terragrunt_config("${get_repo_root()}/configuration.hcl")
  tf_in_automation = get_env("TF_IN_AUTOMATION", false)
  suffix_override  = get_env("SUFFIX_OVERRIDE", "")
  state_folder     = "flowehr/${local.suffix_override != "" ? local.suffix_override : get_env("ENVIRONMENT", "")}"
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "${local.providers.locals.terraform_version}"

  required_providers {
    ${local.providers.locals.required_provider_azure}
  }
}
EOF
}

remote_state {
  backend = local.tf_in_automation ? "azurerm" : "local"
  config = local.tf_in_automation ? {
    resource_group_name  = get_env("CI_RESOURCE_GROUP")
    storage_account_name = get_env("CI_STORAGE_ACCOUNT")
    container_name       = "tfstate"
    key                  = "${local.state_folder}/${path_relative_to_include()}/terraform.tfstate"
  } : {}
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.providers.locals.azure_provider
}

# Here we define common variables to be inhereted by each module (as long as they're set in its variables.tf)
inputs = merge(
  # Add values from the merged config files (root and environment-specific)
  local.configuration.locals.merged_root_config, {

    # And any global env vars that should be made available
    tf_in_automation = local.tf_in_automation

    # Tags to add to every resource that accepts them
    tags = {
      environment = try(local.configuration.locals.merged_root_config.environment, "local")
    }
})

# Databricks cluster deployment failures are transient. https://github.com/UCLH-Foundry/FlowEHR/issues/141
retryable_errors = [
  "cannot create cluster",              # databricks
  "Waiting for deletion of application" # AD application
]

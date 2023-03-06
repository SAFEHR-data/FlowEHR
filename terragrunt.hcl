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

dependency "bootstrap" {
  config_path = "${get_repo_root()}/bootstrap"
}

locals {
  providers = read_terragrunt_config("${get_repo_root()}/providers.hcl")
}

terraform {
  extra_arguments "auto_approve" {
    commands  = ["apply"]
    arguments = ["-auto-approve"]
  }
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "${local.providers.locals.terraform_version}"

  required_providers {
    ${local.providers.locals.required_provider_azure}
    ${local.providers.locals.required_provider_null}
    ${local.providers.locals.required_provider_external}
  }
}
EOF
}

remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = dependency.bootstrap.outputs.mgmt_rg
    storage_account_name = dependency.bootstrap.outputs.mgmt_storage
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
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
  # Add values from the root config.yaml file
  yamldecode(file("${get_repo_root()}/config.yaml")), {

  # And values from terraform bootstrapping
  naming_suffix           = dependency.bootstrap.outputs.naming_suffix
  naming_suffix_truncated = dependency.bootstrap.outputs.naming_suffix_truncated
  deployer_ip_address     = dependency.bootstrap.outputs.deployer_ip_address
  mgmt_rg                 = dependency.bootstrap.outputs.mgmt_rg
  mgmt_acr                = dependency.bootstrap.outputs.mgmt_acr

  # And any global env vars that should be made available
  tf_in_automation = get_env("TF_IN_AUTOMATION", false)

  # Tags to add to every resource that accepts them
  tags = {
    environment = dependency.bootstrap.outputs.environment
  }
})

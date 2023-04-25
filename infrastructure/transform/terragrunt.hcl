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

include "shared" {
  path = "${get_repo_root()}/shared.hcl"
}

locals {
  providers = read_terragrunt_config("${get_repo_root()}/providers.hcl")
}

terraform {
  before_hook "before_hook" {
    commands    = ["apply", "plan"]
    execute     = ["make", "transform-artifacts"]
    working_dir = get_repo_root()
  }
}

dependency "core" {
  config_path = "../core"

  mock_outputs = {
    naming_suffix                         = "naming_suffix"
    naming_suffix_truncated               = "naming_suffix_truncated"
    core_rg_name                          = "core_rg_name"
    core_rg_location                      = "core_rg_location"
    core_vnet_name                        = "core_vnet_name"
    core_subnet_id                        = "core_subnet_id"
    core_kv_id                            = "core_kv_id"
    core_kv_uri                           = "core_kv_uri"
    p0_action_group_id                    = "p0_action_group_id"
    storage_account_name                  = "storage_account_name"
    databricks_host_subnet_name           = "databricks_host_subnet_name"
    databricks_container_subnet_name      = "databricks_container_subnet_name"
    deployer_ip                           = "deployer_ip"
    private_dns_zones                     = "private_dns_zones"
    developers_ad_group_principal_id      = "developers_ad_group_principal_id"
    data_scientists_ad_group_principal_id = "data_scientists_ad_group_principal_id"
    developers_ad_group_display_name      = "developers_ad_group_display_name"
    data_scientists_ad_group_display_name = "data_scientists_ad_group_display_name"
  }
  mock_outputs_allowed_terraform_commands = ["init", "destroy", "validate"]
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "${local.providers.locals.terraform_version}"

  required_providers {
    ${local.providers.locals.required_provider_azure}
    ${local.providers.locals.required_provider_azuread}
    ${local.providers.locals.required_provider_random}
    ${local.providers.locals.required_provider_databricks}
    ${local.providers.locals.required_provider_null}
    ${local.providers.locals.required_provider_time}
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
${local.providers.locals.azure_provider}

provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.databricks.id
  host                        = azurerm_databricks_workspace.databricks.workspace_url
}
EOF
}

inputs = {
  naming_suffix                         = dependency.core.outputs.naming_suffix
  naming_suffix_truncated               = dependency.core.outputs.naming_suffix_truncated
  core_rg_name                          = dependency.core.outputs.core_rg_name
  core_rg_location                      = dependency.core.outputs.core_rg_location
  core_vnet_name                        = dependency.core.outputs.core_vnet_name
  core_subnet_id                        = dependency.core.outputs.core_subnet_id
  core_kv_id                            = dependency.core.outputs.core_kv_id
  core_kv_uri                           = dependency.core.outputs.core_kv_uri
  p0_action_group_id                    = dependency.core.outputs.p0_action_group_id
  core_storage_account_name             = dependency.core.outputs.storage_account_name
  databricks_host_subnet_name           = dependency.core.outputs.databricks_host_subnet_name
  databricks_container_subnet_name      = dependency.core.outputs.databricks_container_subnet_name
  deployer_ip                           = dependency.core.outputs.deployer_ip
  private_dns_zones                     = dependency.core.outputs.private_dns_zones
  developers_ad_group_principal_id      = dependency.core.outputs.developers_ad_group_principal_id
  data_scientists_ad_group_principal_id = dependency.core.outputs.data_scientists_ad_group_principal_id
  developers_ad_group_display_name      = dependency.core.outputs.developers_ad_group_display_name
  data_scientists_ad_group_display_name = dependency.core.outputs.data_scientists_ad_group_display_name
}

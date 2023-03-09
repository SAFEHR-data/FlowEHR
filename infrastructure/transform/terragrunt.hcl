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

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "core" {
  config_path = "../core"
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "${include.root.locals.terraform_version}"

  required_providers {
    ${include.root.locals.required_provider_azure}
    ${include.root.locals.required_provider_azuread}
    ${include.root.locals.required_provider_random}
    ${include.root.locals.required_provider_databricks}
    ${include.root.locals.required_provider_null}
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
${include.root.locals.azure_provider}

provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.databricks.id
  host                        = azurerm_databricks_workspace.databricks.workspace_url
}
EOF
}

inputs = {
  core_rg_name                       = dependency.core.outputs.core_rg_name
  core_rg_location                   = dependency.core.outputs.core_rg_location
  core_vnet_name                     = dependency.core.outputs.core_vnet_name
  core_subnet_id                     = dependency.core.outputs.core_subnet_id
  core_kv_id                         = dependency.core.outputs.core_kv_id
  core_kv_uri                        = dependency.core.outputs.core_kv_uri
  data_source_connections            = get_env("DATA_SOURCE_CONNECTIONS", "[]")
  databricks_host_address_space      = dependency.core.outputs.databricks_host_address_space
  databricks_container_address_space = dependency.core.outputs.databricks_container_address_space
}

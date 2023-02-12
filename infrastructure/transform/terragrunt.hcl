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

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
${include.root.locals.azure_provider}

provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.databricks.id
  host                        = azurerm_databricks_workspace.databricks.workspace_url
}

provider "local" {}
EOF
}

inputs = {
  core_rg_name     = dependency.core.outputs.core_rg_name
  core_rg_location = dependency.core.outputs.core_rg_location
  core_kv_id       = dependency.core.outputs.core_kv_id
  core_kv_uri      = dependency.core.outputs.core_kv_uri
  spark_version    = get_env("SPARK_VERSION", "3.3.1") // This only needs a default for CICD, which can be removed following https://github.com/UCLH-Foundry/FlowEHR/issues/42 
}

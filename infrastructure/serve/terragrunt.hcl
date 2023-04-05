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
  path = find_in_parent_folders()
}

dependency "core" {
  config_path = "../core"

  mock_outputs = {
    core_rg_name                = "core_rg_name"
    core_rg_location            = "core_rg_location"
    core_kv_id                  = "core_kv_id"
    core_vnet_name              = "core_vnet_name"
    core_subnet_id              = "core_subnet_id"
    serve_webapps_address_space = "serve_webapps_address_space"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "destroy"]
}

inputs = {
  core_rg_name                = dependency.core.outputs.core_rg_name
  core_rg_location            = dependency.core.outputs.core_rg_location
  core_kv_id                  = dependency.core.outputs.core_kv_id
  core_vnet_name              = dependency.core.outputs.core_vnet_name
  core_subnet_id              = dependency.core.outputs.core_subnet_id
  serve_webapps_address_space = dependency.core.outputs.serve_webapps_address_space
}

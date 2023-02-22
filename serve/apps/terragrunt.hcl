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
  config_path = "${get_repo_root()}/infrastructure/core"
}

dependency "serve" {
  config_path = "${get_repo_root()}/infrastructure/serve"
}

inputs = {
  core_rg_name     = dependency.core.outputs.core_rg_name
  core_rg_location = dependency.core.outputs.core_rg_location
  core_kv_id       = dependency.core.outputs.core_kv_id

  serve_app_service_plan_name = dependency.serve.outputs.app_service_plan_name
  serve_acr_name              = dependency.serve.outputs.acr_name
  serve_cosmos_account_name   = dependency.serve.outputs.cosmos_account_name
  sql_feature_store_id        = dependency.serve.outputs.sql_feature_store_id
}

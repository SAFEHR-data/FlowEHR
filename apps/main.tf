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

module "platform" {
  for_each                       = toset(["app1", "app2"])
  source                         = "./platform"
  app_id                         = each.key
  local_mode                     = var.local_mode
  resource_group_name            = var.core_rg_name
  location                       = var.core_rg_location
  app_service_plan               = var.serve_app_service_plan_name
  acr_name                       = vr.serve_acr_name
  cosmos_account_name            = var.serve_cosmos_account_name
  transform_sql_feature_store_id = var.transform_sql_feature_store_id
}

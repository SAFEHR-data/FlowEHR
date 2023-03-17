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

# TODO: remove when https://github.com/integrations/terraform-provider-github/pull/1530 is merged
# Needed for manual POST to GitHub APIs and redundant when able to create branch policies in TF
data "external" "github_access_token" {
  program = [
    "python",
    "${path.module}/generate_gh_token.py",
    var.serve.github_app_id,
    var.serve.github_app_installation_id,
    "${path.module}/github.pem"
  ]
}

module "app" {
  for_each                  = var.apps
  source                    = "./app"
  app_id                    = each.key
  app_config                = each.value
  naming_suffix             = var.naming_suffix
  tf_in_automation          = var.tf_in_automation
  environment               = var.environment
  accesses_real_data        = var.accesses_real_data
  webapps_subnet_id         = var.serve_webapps_subnet_id
  resource_group_name       = var.core_rg_name
  location                  = var.core_rg_location
  log_analytics_name        = var.core_log_analytics_name
  app_service_plan_name     = var.serve_app_service_plan_name
  acr_name                  = var.serve_acr_name
  cosmos_account_name       = var.serve_cosmos_account_name
  feature_store_db_name     = var.transform_feature_store_db_name
  feature_store_server_name = var.transform_feature_store_server_name
  github_owner              = var.serve.github_owner
  github_access_token       = data.external.github_access_token.result.token
}

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

data "azurerm_client_config" "current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azurerm_log_analytics_workspace" "core" {
  name                = var.log_analytics_name
  resource_group_name = var.resource_group_name
}

data "azurerm_service_plan" "serve" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
}

data "azurerm_container_registry" "serve" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
}

data "azurerm_cosmosdb_account" "state_store" {
  name                = var.cosmos_account_name
  resource_group_name = var.resource_group_name
}

data "azurerm_mssql_server" "feature_store" {
  name                = var.feature_store_server_name
  resource_group_name = var.resource_group_name
}

data "azuread_user" "contributors_ids" {
  for_each            = var.app_config.contributors
  user_principal_name = each.value
}

data "template_file" "testing_github_workflow" {
  count    = var.app_config.add_testing_slot ? 1 : 0
  template = file("${path.module}/deploy_workflow_template.yaml")
  vars = {
    environment                = local.testing_gh_env
    reusable_workflow_filename = local.acr_deploy_reusable_workflow_filename
    branch_name                = local.testing_branch_name
  }
}

data "template_file" "core_github_workflow" {
  template = file("${path.module}/deploy_workflow_template.yaml")
  vars = {
    environment                = local.core_gh_env
    reusable_workflow_filename = var.app_config.add_testing_slot ? local.slot_swap_reusable_workflow_filename : local.acr_deploy_reusable_workflow_filename
    branch_name                = local.core_branch_name
  }
}

data "azurerm_cosmosdb_sql_role_definition" "data_contributor" {
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
  role_definition_id  = "00000000-0000-0000-0000-000000000002" # Cosmos Data Contributor built-in role ID
}

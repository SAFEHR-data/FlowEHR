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

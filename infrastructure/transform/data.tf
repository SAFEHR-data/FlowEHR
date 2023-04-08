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

data "azurerm_resource_group" "core" {
  name = var.core_rg_name
}

data "azurerm_virtual_network" "core" {
  name                = var.core_vnet_name
  resource_group_name = var.core_rg_name
}

data "azurerm_subnet" "databricks_host" {
  name                 = var.databricks_host_subnet_name
  virtual_network_name = var.core_vnet_name
  resource_group_name  = var.core_rg_name
}

data "azurerm_subnet" "databricks_container" {
  name                 = var.databricks_container_subnet_name
  virtual_network_name = var.core_vnet_name
  resource_group_name  = var.core_rg_name
}

data "azurerm_client_config" "current" {}

# get the MSGraph app
data "azuread_application_published_app_ids" "well_known" {}

data "azurerm_virtual_network" "peered_data_source_networks" {
  for_each            = local.peerings
  name                = each.value.virtual_network_name
  resource_group_name = each.value.resource_group_name
}

data "azurerm_storage_account" "core" {
  name                = var.core_storage_account_name
  resource_group_name = var.core_rg_name
}

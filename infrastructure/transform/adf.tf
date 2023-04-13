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

resource "azurerm_data_factory" "adf" {
  name                = "adf-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name

  managed_virtual_network_enabled = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "adf_can_create_clusters" {
  scope                = azurerm_databricks_workspace.databricks.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

resource "azurerm_data_factory_integration_runtime_azure" "ir" {
  name                    = "FlowEHRIntegrationRuntime"
  data_factory_id         = azurerm_data_factory.adf.id
  location                = var.core_rg_location
  virtual_network_enabled = true
  description             = "Integration runtime in managed vnet"
  time_to_live_min        = 5
}

resource "azurerm_role_assignment" "adf_can_access_kv_secrets" {
  scope                = azurerm_databricks_workspace.databricks.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

resource "azurerm_data_factory_linked_service_azure_databricks" "msi_linked" {
  name            = local.adb_linked_service_name
  data_factory_id = azurerm_data_factory.adf.id
  description     = "Azure Databricks linked service via MSI"
  adb_domain      = "https://${azurerm_databricks_workspace.databricks.workspace_url}"

  msi_work_space_resource_id = azurerm_databricks_workspace.databricks.id

  existing_cluster_id = databricks_cluster.fixed_single_node.cluster_id
}

resource "azurerm_data_factory_linked_service_key_vault" "msi_linked" {
  name            = "KVLinkedServiceViaMSI"
  data_factory_id = azurerm_data_factory.adf.id
  description     = "Key Vault linked service via MSI"
  key_vault_id    = var.core_kv_id
}

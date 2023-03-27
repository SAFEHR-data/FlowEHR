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

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "msi_linked" {
  count                = var.transform.datalake.enabled ? 1 : 0
  name                 = "ADLSLinkedServiceViaMSI"
  data_factory_id      = azurerm_data_factory.adf.id
  description          = "ADLS Gen2"
  use_managed_identity = true
  url                  = "https://${module.datalake[0].storage_account_name}.dfs.core.windows.net"
}




# AAD App + SPN for Databricks -> ADLS Access
resource "azuread_application" "flowehr_databricks_adls" {
  count        = var.transform.datalake.enabled ? 1 : 0
  display_name = local.databricks_app_name
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_application_password" "flowehr_databricks_adls" {
  count                 = var.transform.datalake.enabled ? 1 : 0
  application_object_id = azuread_application.flowehr_databricks_adls[0].object_id
}

resource "azuread_service_principal" "flowehr_databricks_adls" {
  count          = var.transform.datalake.enabled ? 1 : 0
  application_id = azuread_application.flowehr_databricks_adls[0].application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

resource "azurerm_key_vault_secret" "flowehr_databricks_adls_spn_app_id" {
  count        = var.transform.datalake.enabled ? 1 : 0
  name         = "flowehr-dbks-adls-app-id"
  value        = azuread_service_principal.flowehr_databricks_adls[0].application_id
  key_vault_id = var.core_kv_id
}

resource "azurerm_key_vault_secret" "flowehr_databricks_adls_spn_app_secret" {
  count        = var.transform.datalake.enabled ? 1 : 0
  name         = "flowehr-dbks-adls-app-secret"
  value        = azuread_application_password.flowehr_databricks_adls[0].value
  key_vault_id = var.core_kv_id
}

resource "databricks_secret" "flowehr_databricks_adls_spn_app_id" {
  count        = var.transform.datalake.enabled ? 1 : 0
  key          = "flowehr-dbks-adls-app-id"
  string_value = azuread_service_principal.flowehr_databricks_adls[0].application_id
  scope        = databricks_secret_scope.secrets.id
}

resource "databricks_secret" "flowehr_databricks_adls_spn_app_secret" {
  count        = var.transform.datalake.enabled ? 1 : 0
  key          = "flowehr-dbks-adls-app-secret"
  string_value = azuread_application_password.flowehr_databricks_adls[0].value
  scope        = databricks_secret_scope.secrets.id
}


resource "databricks_mount" "adls_bronze" {
  for_each   = { for zone in var.transform.datalake.zones : zone.name => zone }
  name       = "adls-data-lake-${lower(each.value.name)}"
  uri        = "abfss://${lower(each.value.name)}@${module.datalake[0].storage_account_name}.dfs.core.windows.net/"
  cluster_id = databricks_cluster.fixed_single_node.cluster_id
  extra_configs = {
    "fs.azure.account.auth.type" : "OAuth",
    "fs.azure.account.oauth.provider.type" : "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "fs.azure.account.oauth2.client.id" : azuread_application.flowehr_databricks_adls[0].application_id,
    "fs.azure.account.oauth2.client.secret" : "{{secrets/${databricks_secret_scope.secrets.name}/${azurerm_key_vault_secret.flowehr_databricks_adls_spn_app_secret[0].name}}}",
    "fs.azure.account.oauth2.client.endpoint" : "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/token",
    "fs.azure.createRemoteFileSystemDuringInitialization" : "false",
  }

  depends_on = [
    module.datalake
  ]
}

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

# Connect to Datalake from Data Factory using linked service with Managed Identity
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "msi_linked" {
  name                 = "ADLSLinkedServiceViaMSI"
  data_factory_id      = var.adf_id
  description          = "ADLS Gen2"
  use_managed_identity = true
  url                  = "https://${azurerm_storage_account.adls.name}.dfs.core.windows.net"
}

resource "azurerm_role_assignment" "adls_adf_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.adf_identity_object_id
}

# Connect from Databricks using AAD App + SPN
resource "azuread_application" "databricks_adls" {
  display_name = var.databricks_app_name
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_application_password" "databricks_adls" {
  application_object_id = azuread_application.databricks_adls.object_id
}

resource "azuread_service_principal" "databricks_adls" {
  application_id = azuread_application.databricks_adls.application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

resource "azurerm_role_assignment" "adls_databricks_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.databricks_adls.object_id
}

resource "azurerm_key_vault_secret" "databricks_adls_spn_app_id" {
  name         = "flowehr-dbks-adls-app-id"
  value        = azuread_service_principal.databricks_adls.application_id
  key_vault_id = var.core_kv_id
}

resource "azurerm_key_vault_secret" "databricks_adls_spn_app_secret" {
  name         = "flowehr-dbks-adls-app-secret"
  value        = azuread_application_password.databricks_adls.value
  key_vault_id = var.core_kv_id
}

resource "databricks_secret" "databricks_adls_spn_app_id" {
  key          = "flowehr-dbks-adls-app-id"
  string_value = azuread_service_principal.databricks_adls.application_id
  scope        = var.databricks_secret_scope_id
}

resource "databricks_secret" "databricks_adls_spn_app_secret" {
  key          = "flowehr-dbks-adls-app-secret"
  string_value = azuread_application_password.databricks_adls.value
  scope        = var.databricks_secret_scope_id
}

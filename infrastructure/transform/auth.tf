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

# AAD App + secret to set as AAD Admin of SQL Server
resource "azuread_application" "flowehr_sql_owner" {
  display_name = local.sql_owner_app_name
  owners       = [data.azurerm_client_config.current.object_id]
}
resource "azuread_application_password" "flowehr_sql_owner" {
  application_object_id = azuread_application.flowehr_sql_owner.object_id
}
resource "azuread_service_principal" "flowehr_sql_owner" {
  application_id = azuread_application.flowehr_sql_owner.application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

# AAD App + SPN for Databricks -> SQL Access
resource "azuread_application" "flowehr_databricks_sql" {
  display_name = local.databricks_sql_app_name
  owners       = [data.azurerm_client_config.current.object_id]
}
resource "azuread_application_password" "flowehr_databricks_sql" {
  application_object_id = azuread_application.flowehr_databricks_sql.object_id
}
resource "azuread_service_principal" "flowehr_databricks_sql" {
  application_id = azuread_application.flowehr_databricks_sql.application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

# AAD App + secret for connecting to external sources
resource "azuread_application" "flowehr_external_connection" {
  display_name = local.external_connection_app_name
  owners       = [data.azurerm_client_config.current.object_id]
}
resource "azuread_application_password" "flowehr_external_connection" {
  application_object_id = azuread_application.flowehr_external_connection.object_id
}
resource "azuread_service_principal" "flowehr_external_connection" {
  application_id = azuread_application.flowehr_external_connection.application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

# Push secrets to KV
resource "azurerm_key_vault_secret" "sql_server_owner_app_id" {
  name         = "sql-owner-app-id"
  value        = azuread_application.flowehr_sql_owner.application_id
  key_vault_id = var.core_kv_id
}
resource "azurerm_key_vault_secret" "sql_server_owner_secret" {
  name         = "sql-owner-secret"
  value        = azuread_application_password.flowehr_sql_owner.value
  key_vault_id = var.core_kv_id
}
resource "azurerm_key_vault_secret" "sql_server_features_admin_username" {
  name         = "sql-features-admin-username"
  value        = local.sql_server_features_admin_username
  key_vault_id = var.core_kv_id
}
resource "azurerm_key_vault_secret" "sql_server_features_admin_password" {
  name         = "sql-features-admin-password"
  value        = random_password.sql_admin_password.result
  key_vault_id = var.core_kv_id
}
resource "azurerm_key_vault_secret" "flowehr_databricks_sql_spn_app_id" {
  name         = "flowehr-dbks-sql-app-id"
  value        = azuread_service_principal.flowehr_databricks_sql.application_id
  key_vault_id = var.core_kv_id
}
resource "azurerm_key_vault_secret" "flowehr_databricks_sql_spn_app_secret" {
  name         = "flowehr-dbks-sql-app-secret"
  value        = azuread_application_password.flowehr_databricks_sql.value
  key_vault_id = var.core_kv_id
}
resource "azurerm_key_vault_secret" "flowehr_external_connection_app_id" {
  name         = "flowehr-external-conn-app-id"
  value        = azuread_service_principal.flowehr_external_connection.application_id
  key_vault_id = var.core_kv_id
}
resource "azurerm_key_vault_secret" "flowehr_external_connection_app_secret" {
  name         = "flowehr-external-conn-app-secret"
  value        = azuread_application_password.flowehr_external_connection.value
  key_vault_id = var.core_kv_id
}

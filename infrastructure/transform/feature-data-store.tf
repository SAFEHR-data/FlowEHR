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

#TODO remove

resource "random_password" "sql_admin_password" {
  length  = 16
  special = true
}

# Azure SQL logical server, public access disabled - will use private endpoints for access
resource "azurerm_mssql_server" "sql_server_features" {
  name                                 = "sql-server-features-${lower(var.naming_suffix)}"
  location                             = var.core_rg_location
  resource_group_name                  = var.core_rg_name
  version                              = "12.0"
  administrator_login                  = local.sql_server_features_admin_username
  administrator_login_password         = random_password.sql_admin_password.result
  public_network_access_enabled        = var.local_mode
  outbound_network_restriction_enabled = true
  tags                                 = var.tags
}

# optional firewall rule when running in local_mode
resource "azurerm_mssql_firewall_rule" "deployer_ip_exception" {
  count            = var.local_mode == true ? 1 : 0
  name             = "DeployerIP"
  server_id        = azurerm_mssql_server.sql_server_features.id
  start_ip_address = var.deployer_ip_address
  end_ip_address   = var.deployer_ip_address
}

# Enable Transparent Data Encryption (TDE) with a Service Managed Key
resource "azurerm_mssql_server_transparent_data_encryption" "sql_server_features_encryption" {
  server_id = azurerm_mssql_server.sql_server_features.id
}

# Azure SQL database, basic + small for dev
# TODO: Rightsize for prod -> https://github.com/UCLH-Foundry/FlowEHR/issues/63
resource "azurerm_mssql_database" "feature_database" {
  name                 = "sql-db-features"
  server_id            = azurerm_mssql_server.sql_server_features.id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  license_type         = "LicenseIncluded"
  max_size_gb          = 2
  sku_name             = "Basic"
  storage_account_type = "Local"
  zone_redundant       = false
  tags                 = var.tags
}

# AAD App + SPN for Databricks -> SQL Access.
resource "azuread_application" "flowehr_databricks_sql" {
  display_name = "FlowEHR-Databricks-SQL-${var.naming_suffix}"
  owners       = [data.azurerm_client_config.current.object_id]
}
resource "azuread_service_principal" "flowehr_databricks_sql" {
  application_id = azuread_application.flowehr_databricks_sql.application_id
  owners         = [data.azurerm_client_config.current.object_id]
}
resource "azuread_service_principal_password" "flowehr_databricks_sql" {
  service_principal_id = azuread_service_principal.flowehr_databricks_sql.object_id
}

/* TODO - enable when build agent can communicate with KV
# Push secrets to KV
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
  name         = "flowehr-dbks-sql-spn-app-id"
  value        = azuread_service_principal.flowehr_databricks_sql.application_id
  key_vault_id = var.core_kv_id
}
resource "azurerm_key_vault_secret" "flowehr_databricks_sql_spn_app_secret" {
  name         = "flowehr-dbks-sql-spn-app-secret"
  value        = azuread_service_principal_password.flowehr_databricks_sql.value
  key_vault_id = var.core_kv_id
}
*/

# Push SPN details to databricks secret scope
resource "databricks_secret" "flowehr_databricks_sql_spn_app_id" {
  key          = "flowehr-dbks-sql-spn-app-id"
  string_value = azuread_service_principal.flowehr_databricks_sql.application_id
  scope        = databricks_secret_scope.secrets.id
}
resource "databricks_secret" "flowehr_databricks_sql_spn_app_secret" {
  key          = "flowehr-dbks-sql-spn-app-secret"
  string_value = azuread_service_principal_password.flowehr_databricks_sql.value
  scope        = databricks_secret_scope.secrets.id
}

# Private DNS + endpoint for SQL Server
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.core_rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "vnl-sql-${var.naming_suffix}"
  resource_group_name   = var.core_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = data.azurerm_virtual_network.core.id
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "sql_server_features_pe" {
  name                = "pe-sql-feature-data-${var.naming_suffix}"
  resource_group_name = var.core_rg_name
  location            = var.core_rg_location
  subnet_id           = var.core_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "private-service-connection-sql-feature-data-${var.naming_suffix}"
    private_connection_resource_id = azurerm_mssql_server.sql_server_features.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-sql-${var.naming_suffix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

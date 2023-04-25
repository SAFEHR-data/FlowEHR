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

resource "random_password" "sql_admin_password" {
  length      = 16
  min_lower   = 2
  min_upper   = 2
  min_numeric = 2
  min_special = 2
}

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

# Azure SQL logical server, public access disabled - will use private endpoints for access
resource "azurerm_mssql_server" "sql_server_features" {
  name                                 = "sql-server-features-${lower(var.naming_suffix)}"
  location                             = var.core_rg_location
  resource_group_name                  = var.core_rg_name
  version                              = "12.0"
  administrator_login                  = local.sql_server_features_admin_username
  administrator_login_password         = random_password.sql_admin_password.result
  public_network_access_enabled        = !var.accesses_real_data
  outbound_network_restriction_enabled = true
  tags                                 = var.tags
  azuread_administrator {
    login_username = local.sql_owner_app_name
    object_id      = azuread_service_principal.flowehr_sql_owner.object_id
  }
  identity {
    type = "SystemAssigned"
  }
}

# Assign the SQL Identity User.Read.All / GroupMember.Read.All / Application.Read.All
# Doc here: https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-azure-ad-user-assigned-managed-identity
resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_app_role_assignment" "ad_roles" {
  for_each            = toset(["User.Read.All", "GroupMember.Read.All", "Application.Read.All"])
  app_role_id         = azuread_service_principal.msgraph.app_role_ids[each.value]
  principal_object_id = azurerm_mssql_server.sql_server_features.identity[0].principal_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

# Role required for sql serve to write audit logs
resource "azurerm_role_assignment" "sql_can_use_storage" {
  scope                = data.azurerm_storage_account.core.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_mssql_server.sql_server_features.identity[0].principal_id
}

# optional firewall rule when running locally
resource "azurerm_mssql_firewall_rule" "deployer_ip_exception" {
  count            = var.tf_in_automation ? 0 : 1
  name             = "DeployerIP"
  server_id        = azurerm_mssql_server.sql_server_features.id
  start_ip_address = var.deployer_ip
  end_ip_address   = var.deployer_ip
}

# Required for the sql database to access the storage
resource "azurerm_mssql_outbound_firewall_rule" "allow_storage" {
  name      = "${data.azurerm_storage_account.core.name}.blob.core.windows.net"
  server_id = azurerm_mssql_server.sql_server_features.id
}

# Enable Transparent Data Encryption (TDE) with a Service Managed Key
resource "azurerm_mssql_server_transparent_data_encryption" "sql_server_features_encryption" {
  server_id = azurerm_mssql_server.sql_server_features.id
}

# Azure SQL database, basic + small for dev
# TODO: Rightsize for prod -> https://github.com/UCLH-Foundry/FlowEHR/issues/63
resource "azurerm_mssql_database" "feature_database" {
  name         = "sql-db-features"
  server_id    = azurerm_mssql_server.sql_server_features.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  # Use an standard sku for all non-locally deployed environments
  max_size_gb          = var.tf_in_automation ? 250 : 2
  sku_name             = var.tf_in_automation ? "S0" : "Basic"
  storage_account_type = var.tf_in_automation ? "Geo" : "Local"
  zone_redundant       = false
  tags                 = var.tags
}

resource "null_resource" "create_sql_user" {
  # make sure we have the identity created with aad perms, a client + secret to connect with, and an identity to set as dbo
  depends_on = [
    azuread_application_password.flowehr_sql_owner,
    azuread_application.flowehr_databricks_sql,
    azuread_app_role_assignment.ad_roles,
    azurerm_private_endpoint.sql_server_features_pe
  ]

  triggers = {
    app_name        = azuread_application.flowehr_databricks_sql.display_name
    database_name   = azurerm_mssql_database.feature_database.name
    users_to_create = jsonencode(local.sql_users_to_create)
  }

  # set the databricks 'user' app as dbo on the flowehr database
  # load a csv file into a new SQL table
  provisioner "local-exec" {
    command = <<EOF
      SCRIPTS_DIR="../../scripts"
      $SCRIPTS_DIR/retry.sh python $SCRIPTS_DIR/sql/create_sql_user.py
      $SCRIPTS_DIR/retry.sh python $SCRIPTS_DIR/sql/load_csv_data.py
    EOF
    environment = {
      SERVER          = azurerm_mssql_server.sql_server_features.fully_qualified_domain_name
      DATABASE        = azurerm_mssql_database.feature_database.name
      CLIENT_ID       = azuread_application.flowehr_sql_owner.application_id
      CLIENT_SECRET   = azuread_application_password.flowehr_sql_owner.value
      USERS_TO_CREATE = jsonencode(local.sql_users_to_create)
      PATH_TO_CSV     = "../../scripts/sql/nhsd-diabetes-test.csv"
      TABLE_NAME      = "deploy-test-diabetes"
    }
  }
}

# AAD App + SPN for Databricks -> SQL Access
resource "azuread_application" "flowehr_databricks_sql" {
  display_name = local.databricks_app_name
  owners       = [data.azurerm_client_config.current.object_id]
}
resource "azuread_application_password" "flowehr_databricks_sql" {
  application_object_id = azuread_application.flowehr_databricks_sql.object_id
}
resource "azuread_service_principal" "flowehr_databricks_sql" {
  application_id = azuread_application.flowehr_databricks_sql.application_id
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
    private_dns_zone_ids = [var.private_dns_zones["sql"].id]
  }
}

resource "azuread_group" "ad_group_apps" {
  display_name     = "${var.naming_suffix} flowehr-apps"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true
}

resource "azurerm_monitor_activity_log_alert" "feature_database_firewall_update" {
  name                = "activity-log-alert-sql-fw-${var.naming_suffix}"
  resource_group_name = var.core_rg_name
  scopes              = [data.azurerm_resource_group.core.id]
  description         = "Monitor security updates to the MSSQL server firewall"

  criteria {
    resource_id    = azurerm_mssql_server.sql_server_features.id
    operation_name = "Microsoft.Sql/servers/firewallRules/write"
    category       = "Administrative"
    level          = "Informational"
  }

  action {
    action_group_id = var.p0_action_group_id
  }
}

resource "azurerm_mssql_server_extended_auditing_policy" "sql_server_features" {
  storage_endpoint       = data.azurerm_storage_account.core.primary_blob_endpoint
  server_id              = azurerm_mssql_server.sql_server_features.id
  retention_in_days      = 90
  log_monitoring_enabled = false # true if posting logs to azure monitor, but requires eventhub

  storage_account_subscription_id = data.azurerm_client_config.current.subscription_id

  depends_on = [
    azurerm_role_assignment.sql_can_use_storage,
    azurerm_mssql_outbound_firewall_rule.allow_storage
  ]
}

resource "azurerm_storage_container" "mssql_vulnerability_assessment" {
  name                  = "mssqlvulnerabilityassessment"
  storage_account_name  = data.azurerm_storage_account.core.name
  container_access_type = "private"
}

resource "azurerm_mssql_server_security_alert_policy" "sql_server_features" {
  resource_group_name = var.core_rg_name
  server_name         = azurerm_mssql_server.sql_server_features.name
  state               = "Enabled"
}

resource "azurerm_mssql_server_vulnerability_assessment" "sql_server_features" {
  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.sql_server_features.id
  storage_container_path          = "${data.azurerm_storage_account.core.primary_blob_endpoint}${azurerm_storage_container.mssql_vulnerability_assessment.name}/"

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = [for person in var.monitoring.alert_recipients : person.email]
  }
}

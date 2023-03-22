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

resource "databricks_secret" "data_source_fqdns" {
  for_each = { for connection in var.data_source_connections :
    connection.name => connection.fqdn
  }
  key          = "flowehr-dbks-${each.key}-fqdn"
  string_value = each.value
  scope        = databricks_secret_scope.secrets.id
}

resource "databricks_secret" "data_source_connections" {
  for_each = { for connection in var.data_source_connections :
    connection.name => connection.database
  }
  key          = "flowehr-dbks-${each.key}-database"
  string_value = each.value
  scope        = databricks_secret_scope.secrets.id
}

resource "databricks_secret" "data_source_usernames" {
  for_each = { for connection in var.data_source_connections :
    connection.name => connection.username
  }
  key          = "flowehr-dbks-${each.key}-username"
  string_value = each.value
  scope        = databricks_secret_scope.secrets.id
}

resource "databricks_secret" "data_source_passwords" {
  for_each = { for connection in var.data_source_connections :
    connection.name => connection.password
  }
  key          = "flowehr-dbks-${each.key}-password"
  string_value = each.value
  scope        = databricks_secret_scope.secrets.id
}

# Push SPN details to databricks secret scope
resource "databricks_secret" "flowehr_databricks_sql_spn_app_id" {
  key          = "flowehr-dbks-sql-app-id"
  string_value = azuread_service_principal.flowehr_databricks_sql.application_id
  scope        = databricks_secret_scope.secrets.id
}

resource "databricks_secret" "flowehr_databricks_sql_spn_app_secret" {
  key          = "flowehr-dbks-sql-app-secret"
  string_value = azuread_application_password.flowehr_databricks_sql.value
  scope        = databricks_secret_scope.secrets.id
}
resource "databricks_secret" "flowehr_databricks_sql_fqdn" {
  key          = "flowehr-dbks-sql-fqdn"
  string_value = azurerm_mssql_server.sql_server_features.fully_qualified_domain_name
  scope        = databricks_secret_scope.secrets.id
}
resource "databricks_secret" "flowehr_databricks_sql_database" {
  key          = "flowehr-dbks-sql-database"
  string_value = azurerm_mssql_database.feature_database.name
  scope        = databricks_secret_scope.secrets.id
}

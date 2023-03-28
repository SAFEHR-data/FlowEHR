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

resource "azurerm_cosmosdb_sql_database" "app" {
  name                = "${var.app_id}-state"
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
}

resource "azurerm_cosmosdb_sql_role_definition" "webapp" {
  name                = "${var.app_id}-AccessCosmosSingleDB"
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
  assignable_scopes   = ["${data.azurerm_cosmosdb_account.state_store.id}/dbs/${azurerm_cosmosdb_sql_database.app.name}"]

  permissions {
    data_actions = ["Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*"]
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "webapp" {
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.webapp.id
  principal_id        = azurerm_linux_web_app.app.identity[0].principal_id
  scope               = "${data.azurerm_cosmosdb_account.state_store.id}/dbs/${azurerm_cosmosdb_sql_database.app.name}"
}

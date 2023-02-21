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

resource "azurerm_linux_web_app" "app" {
  name                = "webapp-${var.app_id}-${var.naming_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.app_service_plan_id

  site_config {
    linux_fx_version                        = "DOCKER|${var.acr_name}/${var.app_id}:latest"
    container_registry_use_managed_identity = true
    remote_debugging_enabled                = var.local_mode
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL = "https://${var.acr_name}.azurecr.io"
  }

  identity {
    type = "SystemAssigned"
  }

  auth_settings {
    enabled = true
  }
}

resource "azurerm_role_assignment" "webapp_acr" {
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.serve.id
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

resource "azurerm_cosmosdb_sql_database" "app" {
  name                = "${var.app_id}-state"
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
}

resource "azurerm_cosmosdb_sql_container" "app" {
  name                = "example-container"
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
  database_name       = azurerm_cosmosdb_sql_database.app.name
  partition_key_path  = "/id"

  autoscale_settings {
    max_throughput = 1000
  }
}

resource "azurerm_app_service_connection" "cosmos" {
  name               = "cosmos-serviceconnector"
  app_service_id     = azurerm_linux_web_app.app.id
  target_resource_id = azurerm_cosmosdb_sql_database.app.id

  authentication {
    type = "systemAssignedIdentity"
  }
}

resource "azurerm_app_service_connection" "sql" {
  name               = "sql-serviceconnector"
  app_service_id     = azurerm_linux_web_app.app.id
  target_resource_id = var.sql_feature_store_id

  authentication {
    type = "systemAssignedIdentity"
  }
}

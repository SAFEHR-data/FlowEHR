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

resource "azurerm_application_insights" "app" {
  name                       = "ai-${replace(var.app_id, "_", "-")}-${var.naming_suffix}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  workspace_id               = data.azurerm_log_analytics_workspace.core.id
  application_type           = "web"
  internet_ingestion_enabled = var.tf_in_automation ? false : true
}

resource "azurerm_linux_web_app" "app" {
  name                      = "webapp-${replace(var.app_id, "_", "-")}-${var.naming_suffix}"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  service_plan_id           = data.azurerm_service_plan.serve.id
  virtual_network_subnet_id = var.webapps_subnet_id
  https_only                = true

  site_config {
    container_registry_use_managed_identity = true
    remote_debugging_enabled                = !var.tf_in_automation

    application_stack {
      docker_image     = "${var.acr_name}.azurecr.io/${var.app_id}"
      docker_image_tag = "latest"
    }
  }

  app_settings = merge(var.app_config.env, {
    APPINSIGHTS_INSTRUMENTATIONKEY             = azurerm_application_insights.app.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING      = azurerm_application_insights.app.connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
    DOCKER_ENABLE_CI                           = true
    COSMOS_STATE_STORE_ENDPOINT                = data.azurerm_cosmosdb_account.state_store.endpoint
    FEATURE_STORE_CONNECTION_STRING            = local.feature_store_odbc
    ENVIRONMENT                                = var.environment
  })

  identity {
    type = "SystemAssigned"
  }

  logs {
    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
}

resource "azurerm_role_assignment" "webapp_acr" {
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.serve.id
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

# Create a web hook that triggers automated deployment of the Docker image
resource "azurerm_container_registry_webhook" "webhook" {
  name                = "acrwh${replace(replace(var.app_id, "_", ""), "-", "")}"
  resource_group_name = var.resource_group_name
  location            = var.location
  registry_name       = data.azurerm_container_registry.serve.name

  service_uri = "https://${azurerm_linux_web_app.app.site_credential[0].name}:${azurerm_linux_web_app.app.site_credential[0].password}@${lower(azurerm_linux_web_app.app.name)}.scm.azurewebsites.net/api/registry/webhook"
  status      = "enabled"
  scope       = "${var.app_id}:latest"
  actions     = ["push"]

  custom_headers = {
    "Content-Type" = "application/json"
  }
}

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

// TODO: once Feature Store SQL SPN stuff is in, add connection from App Service here

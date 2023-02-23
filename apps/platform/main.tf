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
  name                       = "ai-${local.app_id_truncated}-${var.naming_suffix}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  workspace_id               = data.azurerm_log_analytics_workspace.core.id
  application_type           = "web"
  internet_ingestion_enabled = var.local_mode ? true : false
}

resource "azurerm_linux_web_app" "app" {
  name                      = "webapp-${local.app_id_truncated}-${var.naming_suffix}"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  service_plan_id           = data.azurerm_service_plan.serve.id
  virtual_network_subnet_id = var.webapps_subnet_id

  site_config {
    container_registry_use_managed_identity = true
    remote_debugging_enabled                = var.local_mode

    application_stack {
      docker_image     = "${var.acr_name}.azurecr.io/${var.app_id}"
      docker_image_tag = "latest"
    }
  }

  app_settings = merge(var.app_config.env, {
    APPINSIGHTS_INSTRUMENTATIONKEY             = azurerm_application_insights.app.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING      = azurerm_application_insights.app.connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
  })

  identity {
    type = "SystemAssigned"
  }

  auth_settings {
    enabled = true
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

    failed_request_tracing = true
  }
}

resource "azurerm_role_assignment" "webapp_acr" {
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.serve.id
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

# Create a web hook that triggers automated deployment of the Docker image
resource "azurerm_container_registry_webhook" "webhook" {
  name                = "WH${local.app_id_truncated}"
  resource_group_name = var.resource_group_name
  location            = var.location
  registry_name       = data.azurerm_container_registry.serve.name

  service_uri = "https://${azurerm_linux_web_app.app.site_credential[0].name}:${azurerm_linux_web_app.app.site_credential[0].password}@${lower(azurerm_linux_web_app.app.name)}.scm.azurewebsites.net/docker/hook"
  status      = "enabled"
  scope       = var.app_id
  actions     = ["push"]

  custom_headers = {
    "Content-Type" = "application/json"
  }
}

resource "azurerm_cosmosdb_sql_database" "app" {
  name                = "${local.app_id_truncated}-state"
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
}

resource "azurerm_cosmosdb_sql_container" "app" {
  name                = "main"
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
  database_name       = azurerm_cosmosdb_sql_database.app.name
  partition_key_path  = "/id"
}

resource "azurerm_app_service_connection" "cosmos" {
  name               = "cosmos_state_store"
  app_service_id     = azurerm_linux_web_app.app.id
  target_resource_id = azurerm_cosmosdb_sql_database.app.id

  authentication {
    type = "systemAssignedIdentity"
  }
}

resource "azurerm_app_service_connection" "sql" {
  name               = "sql_feature_store"
  app_service_id     = azurerm_linux_web_app.app.id
  target_resource_id = var.feature_store_id

  authentication {
    type = "systemAssignedIdentity"
  }
}

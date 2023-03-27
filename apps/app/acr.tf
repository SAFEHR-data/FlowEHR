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

resource "azurerm_role_assignment" "webapp_acr" {
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.serve.id
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

resource "azurerm_role_assignment" "webapp_testing_slot_acr" {
  count                = var.app_config.add_testing_slot ? 1 : 0
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.serve.id
  principal_id         = azurerm_linux_web_app_slot.testing[0].identity[0].principal_id
}

# Create a web hook that triggers automated deployment of the Docker image
resource "azurerm_container_registry_webhook" "webhook" {
  count               = var.app_config.add_testing_slot ? 0 : 1
  name                = "acrwh${local.app_id_truncated}"
  resource_group_name = var.resource_group_name
  location            = var.location
  registry_name       = data.azurerm_container_registry.serve.name

  service_uri = "https://${local.site_credential_name}:${local.site_credential_password}@${lower(azurerm_linux_web_app.app.name)}.scm.azurewebsites.net/api/registry/webhook"
  status      = "enabled"
  scope       = "${local.acr_repository}:latest"
  actions     = ["push"]

  custom_headers = {
    "Content-Type" = "application/json"
  }
}

# Create ACR repository token for app to use in cicd to push images
resource "azurerm_container_registry_scope_map" "app_access" {
  name                    = "acr-scopes-${local.app_id_truncated}"
  container_registry_name = data.azurerm_container_registry.serve.name
  resource_group_name     = var.resource_group_name

  actions = [
    "repositories/${local.acr_repository}/content/read",
    "repositories/${local.acr_repository}/content/write"
  ]
}

resource "azurerm_container_registry_token" "app_access" {
  name                    = local.app_id_truncated
  container_registry_name = data.azurerm_container_registry.serve.name
  resource_group_name     = var.resource_group_name
  scope_map_id            = azurerm_container_registry_scope_map.app_access.id
}

resource "azurerm_container_registry_token_password" "app_access" {
  container_registry_token_id = azurerm_container_registry_token.app_access.id
  password1 {}
}

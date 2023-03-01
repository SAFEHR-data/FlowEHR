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

resource "github_repository" "app" {
  name        = var.app_id
  description = var.app_config.description
  visibility  = "private"

  # template {
  #   owner      = "UCLH-Foundry"
  #   repository = var.app_config.managed_repo.template
  # }
}

resource "github_team" "contributors" {
  name        = "${var.app_id} - contributors"
  description = "Contributors to the ${var.app_id} FlowEHR app."
}

resource "azurerm_container_registry_scope_map" "app_access" {
  name                    = "acr-scopes-${replace(var.app_id, "_", "")}"
  container_registry_name = data.azurerm_container_registry.serve.name
  resource_group_name     = var.resource_group_name

  actions = [
    "repositories/${var.app_id}/content/read",
    "repositories/${var.app_id}/content/write"
  ]
}

resource "azurerm_container_registry_token" "app_access" {
  name                    = replace(replace(var.app_id, "_", ""), "-", "")
  container_registry_name = data.azurerm_container_registry.serve.name
  resource_group_name     = var.resource_group_name
  scope_map_id            = azurerm_container_registry_scope_map.app_access.id
}

resource "azurerm_container_registry_token_password" "app_access" {
  container_registry_token_id = azurerm_container_registry_token.app_access.id
  password1 {}
}

resource "github_repository_environment" "app" {
  repository  = github_repository.app.name
  environment = var.environment
}

resource "github_actions_environment_secret" "acr_token" {
  repository      = github_repository.app.name
  environment     = github_repository_environment.app.environment
  secret_name     = "ACR_TOKEN"
  plaintext_value = azurerm_container_registry_token_password.app_access.password1[0].value
}

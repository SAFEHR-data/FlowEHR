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

resource "azurerm_container_group" "build_agent" {
  count               = var.local_mode == true ? 0 : 1
  name                = "cg-build-agent-${var.naming_suffix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = azurerm_resource_group.core.location
  subnet_ids          = [azurerm_subnet.core_containers.id]
  ip_address_type     = "Private"
  os_type             = "Linux"
  restart_policy      = "Never"

  container {
    name   = "devcontainer"
    image  = "${data.azurerm_container_registry.devcontainer[0].login_server}/${var.devcontainer_image_name}:${var.devcontainer_tag}"
    cpu    = "1"
    memory = "4"
    # commands = ["/bin/sleep", "infinity"] # Keep container runniner for debuging
    commands = ["/tmp/library-scripts/start-gh-runner.sh"]

    environment_variables = {
      GITHUB_REPOSITORY  = var.github_repository
      GITHUB_RUNNER_NAME = var.github_runner_name
    }

    secure_environment_variables = {
      GITHUB_RUNNER_TOKEN = var.github_runner_token
    }

    # Needs to be defined but is unused
    ports {
      port     = 22
      protocol = "TCP"
    }
  }

  image_registry_credential {
    username = data.azurerm_container_registry.devcontainer[0].admin_username
    password = data.azurerm_container_registry.devcontainer[0].admin_password
    server   = data.azurerm_container_registry.devcontainer[0].login_server
  }
}

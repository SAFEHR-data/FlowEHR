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

data "azurerm_client_config" "current" {}


# az acr list --query "[? name == 'acrsvce9c2'].[ resourceGroup]"
data "external" "devcontainer_acr" {
  program = ["az", "az", "acr", "list", "--query", "\"[? name == '${var.}']\""]
}


data "azurerm_container_registry" "gh_actions" {
  name                = var.gh_actions_acr_name
  resource_group_name = var.gh_actions_resource_group_name
}

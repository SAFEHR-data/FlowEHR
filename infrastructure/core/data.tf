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

# Find the resource group which contains the ACR holding the devcontainer
data "external" "devcontainer_acr" {
  count = var.local_mode == true ? 0 : 1
  program = [
    "bash", "-c",
    <<EOF
rg=$(az acr list --query "[? name == '${var.devcontainer_acr_name}'].[resourceGroup] | [0]" -o tsv)
echo "{\"resourceGroup\": \"$rg\"}"
EOF
  ]
}

data "azurerm_container_registry" "devcontainer" {
  count               = var.local_mode == true ? 0 : 1
  name                = var.devcontainer_acr_name
  resource_group_name = data.external.devcontainer_acr[0].result["resourceGroup"]
}

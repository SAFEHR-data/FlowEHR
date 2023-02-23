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

resource "azurerm_subnet" "serve_webapps" {
  name                                          = "subnet-serve-webapps-${var.naming_suffix}"
  resource_group_name                           = var.core_rg_name
  virtual_network_name                          = data.azurerm_virtual_network.core.name
  private_endpoint_network_policies_enabled     = false
  private_link_service_network_policies_enabled = true
  address_prefixes                              = [var.subnet_address_spaces[4]]

  delegation {
    name = "web-app-vnet-integration"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

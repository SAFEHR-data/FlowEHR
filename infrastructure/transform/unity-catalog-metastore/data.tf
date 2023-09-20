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

data "azurerm_resource_group" "core_rg" {
  name = var.core_rg_name
}

data "azurerm_virtual_network" "core_vnet" {
  name                = "vnet-${var.naming_suffix}"
  resource_group_name = data.azurerm_resource_group.core_rg.name
}

data "azurerm_subnet" "shared_subnet" {
  name                 = "subnet-core-shared-${var.naming_suffix}"
  virtual_network_name = data.azurerm_virtual_network.core_vnet.name
  resource_group_name  = data.azurerm_resource_group.core_rg.name
}

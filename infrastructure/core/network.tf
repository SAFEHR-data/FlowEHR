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

resource "random_integer" "ip" {
  count = var.use_random_address_space ? 2 : 0
  min   = 0
  max   = 255
  keepers = {
    suffix = var.naming_suffix
  }
}

resource "azurerm_virtual_network" "core" {
  name                = "vnet-${var.naming_suffix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = azurerm_resource_group.core.location
  tags                = var.tags

  address_space = [
    var.use_random_address_space
    ? "10.${random_integer.ip[0].result}.${random_integer.ip[1].result}.0/24"
    : var.core_address_space
  ]
}

resource "azurerm_subnet" "core_shared" {
  name                 = "subnet-core-shared-${var.naming_suffix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = [local.core_shared_address_space]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]
}

resource "azurerm_subnet" "core_container" {
  name                 = "subnet-core-containers-${var.naming_suffix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = [local.core_container_address_space]

  delegation {
    name = "delegation-core-containers-${var.naming_suffix}"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "all" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.core.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "all" {
  for_each              = local.private_dns_zones
  name                  = "vnl-${each.key}-${var.naming_suffix}"
  resource_group_name   = azurerm_resource_group.core.name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.core.id
  tags                  = var.tags

  depends_on = [
    azurerm_private_dns_zone.all
  ]
}

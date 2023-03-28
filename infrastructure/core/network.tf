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

resource "azurerm_network_security_group" "core" {
  name                = "nsg-default-${var.naming_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name

  security_rule {
    name                       = "deny-internet-outbound-override"
    description                = "Blocks outbound internet traffic unless an explicit outbound-allow rule exists. Overrides the default rule 65001"
    priority                   = 2000
    access                     = "Deny"
    protocol                   = "*"
    direction                  = "Outbound"
    destination_address_prefix = "Internet"
    destination_port_range     = 443
    source_address_prefix      = "*"
    source_port_range          = "*"
  }
}

resource "azurerm_network_watcher_flow_log" "data_sources" {
  name                      = "nw-log-${var.naming_suffix}"
  resource_group_name       = var.network_watcher_resource_group_name
  network_watcher_name      = var.network_watcher_name
  network_security_group_id = azurerm_network_security_group.core.id
  storage_account_id        = azurerm_storage_account.core.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.core.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.core.location
    workspace_resource_id = azurerm_log_analytics_workspace.core.id
    interval_in_minutes   = 10
  }
}

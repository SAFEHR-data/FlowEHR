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
    suffix = local.naming_suffix
  }
}

resource "azurerm_virtual_network" "core" {
  name                = "vnet-${local.naming_suffix}"
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
  name                 = "subnet-core-shared-${local.naming_suffix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = [local.core_shared_address_space]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]
}

resource "azurerm_subnet" "core_container" {
  name                 = "subnet-core-containers-${local.naming_suffix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = [local.core_container_address_space]

  delegation {
    name = "delegation-core-containers-${local.naming_suffix}"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "created_zones" {
  for_each            = var.create_dns_zones ? local.required_private_dns_zones : {}
  name                = each.value
  resource_group_name = azurerm_resource_group.core.name
  tags                = var.tags
}

# If create_dns_zones is true, we link to the created zones, otherwise link to pre-existing zones
resource "azurerm_private_dns_zone_virtual_network_link" "flowehr" {
  for_each              = var.create_dns_zones ? azurerm_private_dns_zone.created_zones : data.azurerm_private_dns_zone.existing_zones
  name                  = "vnl-${each.value.name}-flwr-${local.naming_suffix}"
  resource_group_name   = azurerm_resource_group.core.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.core.id
  tags                  = var.tags
}

resource "azurerm_virtual_network_peering" "ci_to_flowehr" {
  count                     = var.tf_in_automation ? 1 : 0
  name                      = "peer-ci-to-flwr-${local.naming_suffix}"
  resource_group_name       = var.ci_rg_name
  virtual_network_name      = var.ci_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.core.id
}

resource "azurerm_virtual_network_peering" "flowehr_to_ci" {
  count                     = var.tf_in_automation ? 1 : 0
  name                      = "peer-flwr-${local.naming_suffix}-to-ci"
  resource_group_name       = azurerm_resource_group.core.name
  virtual_network_name      = azurerm_virtual_network.core.name
  remote_virtual_network_id = data.azurerm_virtual_network.ci[0].id
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-${local.naming_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  subnet_id           = azurerm_subnet.core_shared.id

  private_dns_zone_group {
    name = "private-dns-zone-group-kv-${local.naming_suffix}"
    private_dns_zone_ids = [
      var.create_dns_zones
      ? azurerm_private_dns_zone.created_zones["keyvault"].id
      : data.azurerm_private_dns_zone.existing_zones["keyvault"].id
    ]
  }

  private_service_connection {
    name                           = "private-service-connection-kv-${local.naming_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.core.id
    subresource_names              = ["Vault"]
  }
}

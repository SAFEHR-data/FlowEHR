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

resource "azurerm_network_security_group" "databricks" {
  name                = "nsg-dbks-${var.naming_suffix}"
  resource_group_name = var.core_rg_name
  location            = var.core_rg_location
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "databricks_host" {
  subnet_id                 = data.azurerm_subnet.databricks_host.id
  network_security_group_id = azurerm_network_security_group.databricks.id
}

resource "azurerm_subnet_network_security_group_association" "databricks_container" {
  subnet_id                 = data.azurerm_subnet.databricks_container.id
  network_security_group_id = azurerm_network_security_group.databricks.id
}

# Add UDRs to ensure correct routing for Databricks traffic
# See https://learn.microsoft.com/en-gb/azure/databricks/administration-guide/cloud-configurations/azure/udr?WT.mc_id=Portal-Microsoft_Azure_Support#--configure-user-defined-routes-with-azure-service-tags
resource "azurerm_route_table" "databricks_udrs" {
  name                = "rt-dbks-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  tags                = var.tags
}

resource "azurerm_route" "databricks_service_tags" {
  for_each            = local.databricks_service_tags
  name                = each.key
  resource_group_name = var.core_rg_name
  route_table_name    = azurerm_route_table.databricks_udrs.name
  address_prefix      = each.value
  next_hop_type       = "Internet"
}

resource "azurerm_route" "databricks_extinfra_ips" {
  for_each            = try(toset(local.databricks_udr_ips[var.core_rg_location].extinfra), toset([]))
  name                = "extinfra-${index(local.databricks_udr_ips[var.core_rg_location].extinfra, each.value)}"
  resource_group_name = var.core_rg_name
  route_table_name    = azurerm_route_table.databricks_udrs.name
  address_prefix      = each.value
  next_hop_type       = "Internet"
}

resource "azurerm_subnet_route_table_association" "databricks_host" {
  subnet_id      = data.azurerm_subnet.databricks_host.id
  route_table_id = azurerm_route_table.databricks_udrs.id
}

resource "azurerm_subnet_route_table_association" "databricks_container" {
  subnet_id      = data.azurerm_subnet.databricks_container.id
  route_table_id = azurerm_route_table.databricks_udrs.id
}

resource "azurerm_subnet_route_table_association" "shared" {
  subnet_id      = var.core_subnet_id
  route_table_id = azurerm_route_table.databricks_udrs.id
}

resource "azurerm_private_endpoint" "databricks_control_plane" {
  name                = "pe-dbks-cp-${var.naming_suffix}"
  resource_group_name = var.core_rg_name
  location            = var.core_rg_location
  subnet_id           = var.core_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "private-service-connection-databricks-control-plane-${var.naming_suffix}"
    private_connection_resource_id = azurerm_databricks_workspace.databricks.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-databricks-control-plane-${var.naming_suffix}"
    private_dns_zone_ids = [var.private_dns_zones["databricks"].id]
  }
}

resource "azurerm_private_endpoint" "databricks_filesystem" {
  name                = "pe-dbks-fs-${var.naming_suffix}"
  resource_group_name = var.core_rg_name
  location            = var.core_rg_location
  subnet_id           = var.core_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "private-service-connection-databricks-filesystem-${var.naming_suffix}"
    private_connection_resource_id = join("", [azurerm_databricks_workspace.databricks.managed_resource_group_id, "/providers/Microsoft.Storage/storageAccounts/${local.dbfs_storage_account_name}"])
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-databricks-filesystem-${var.naming_suffix}"
    private_dns_zone_ids = [var.private_dns_zones["blob"].id]
  }
}

resource "azurerm_virtual_network_peering" "data_source_to_flowehr" {
  for_each                  = local.peerings
  name                      = "peer-${substr(each.key, 0, 30)}-to-${var.naming_suffix}"
  resource_group_name       = each.value.resource_group_name
  virtual_network_name      = each.value.virtual_network_name
  remote_virtual_network_id = data.azurerm_virtual_network.core.id
}

resource "azurerm_virtual_network_peering" "flowehr_to_data_source" {
  for_each                  = local.peered_vnet_ids
  name                      = "peer-${var.naming_suffix}-to-${substr(each.key, 0, 30)}"
  resource_group_name       = var.core_rg_name
  virtual_network_name      = data.azurerm_virtual_network.core.name
  remote_virtual_network_id = each.value
}

resource "azurerm_private_dns_zone_virtual_network_link" "data_sources" {
  for_each              = { for idx, item in local.data_source_dns_zones : idx => item }
  name                  = "vnl-${each.key}-flwr-${var.naming_suffix}"
  private_dns_zone_name = each.value.dns_zone_name
  virtual_network_id    = data.azurerm_virtual_network.core.id
  resource_group_name   = var.private_dns_zones_rg == null ? each.value.resource_group_name : var.private_dns_zones_rg
}

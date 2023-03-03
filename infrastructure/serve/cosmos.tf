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

resource "azurerm_cosmosdb_account" "serve" {
  name                = "cosmos-serve-${var.naming_suffix_truncated}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  tags                = var.tags

  public_network_access_enabled = !var.tf_in_automation
  local_authentication_disabled = var.tf_in_automation

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = var.core_rg_location
    failover_priority = 0
  }
}

resource "azurerm_private_dns_zone" "cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.core_rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos" {
  name                  = "vnl-cosmos-${var.naming_suffix}"
  resource_group_name   = var.core_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos.name
  virtual_network_id    = data.azurerm_virtual_network.core.id
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "cosmos" {
  name                = "pe-cosmos-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  subnet_id           = var.core_subnet_id
  tags                = var.tags

  private_dns_zone_group {
    name                 = "private-dns-zone-group-cosmos-${var.naming_suffix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos.id]
  }

  private_service_connection {
    name                           = "private-service-connection-cosmos-${var.naming_suffix}"
    private_connection_resource_id = azurerm_cosmosdb_account.serve.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }
}

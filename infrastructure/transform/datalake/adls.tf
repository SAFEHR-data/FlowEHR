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

resource "azurerm_storage_account" "adls" {
  name                              = "adls${replace(lower(var.naming_suffix), "-", "")}"
  resource_group_name               = var.core_rg_name
  location                          = var.core_rg_location
  account_tier                      = "Standard"
  account_replication_type          = "GRS"
  account_kind                      = "StorageV2"
  is_hns_enabled                    = true
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = !var.tf_in_automation
  tags                              = var.tags

  network_rules {
    bypass         = ["AzureServices"]
    default_action = "Deny"
    ip_rules       = var.tf_in_automation ? null : [var.deployer_ip]
  }

  blob_properties {
    container_delete_retention_policy {
      days = 7
    }

    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_role_assignment" "adls_deployer_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Add IP exception when deploying locally
resource "azurerm_storage_account_network_rules" "adls" {
  storage_account_id = azurerm_storage_account.adls.id
  default_action     = "Deny"
  ip_rules           = var.tf_in_automation == true ? [] : [var.deployer_ip]
}

# Create filesystem for each zone
resource "azurerm_storage_container" "adls_zone" {
  for_each              = var.zones
  name                  = lower(each.value)
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"

  depends_on = [
    azurerm_storage_account_network_rules.adls,
    azurerm_role_assignment.adls_deployer_contributor
  ]
}

resource "azurerm_private_endpoint" "adls" {
  name                = "adls-${lower(var.naming_suffix)}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  subnet_id           = var.core_subnet_id

  private_service_connection {
    name                           = "adls-${lower(var.naming_suffix)}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.adls.id
    subresource_names              = ["dfs"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-adls-${var.naming_suffix}"
    private_dns_zone_ids = [var.private_dns_zones["adls"].id]
  }
}

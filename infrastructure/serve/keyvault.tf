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

resource "azurerm_key_vault" "serve" {
  name                          = "kv-${var.naming_suffix_truncated}-srv"
  location                      = var.core_rg_location
  resource_group_name           = var.core_rg_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption   = false
  public_network_access_enabled = !var.accesses_real_data
  soft_delete_retention_days    = 7
  purge_protection_enabled      = var.accesses_real_data
  enable_rbac_authorization     = true
  sku_name                      = "standard"
  tags                          = var.tags
}

resource "azurerm_role_assignment" "deployer_can_administrate_kv" {
  scope                = azurerm_key_vault.serve.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "apps_can_read_secrets" {
  scope                = azurerm_key_vault.serve.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.apps_ad_group_principal_id
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-${var.naming_suffix}-serve"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  subnet_id           = var.core_subnet_id
  tags                = var.tags

  private_dns_zone_group {
    name                 = "private-dns-zone-group-kv-${var.naming_suffix}"
    private_dns_zone_ids = [var.private_dns_zones["keyvault"].id]
  }

  private_service_connection {
    name                           = "private-service-connection-kv-${var.naming_suffix}-serve"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.serve.id
    subresource_names              = ["Vault"]
  }

  depends_on = [
    azurerm_role_assignment.deployer_can_administrate_kv
  ]
}

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

resource "azurerm_application_insights" "serve" {
  name                = "aml-ai-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_storage_account" "aml" {
  name                              = "strgaml${var.naming_suffix_truncated}"
  location                          = var.core_rg_location
  resource_group_name               = var.core_rg_name
  account_tier                      = "Standard"
  account_replication_type          = "GRS"
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = !var.tf_in_automation
  enable_https_traffic_only         = true
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

    change_feed_enabled = true
  }
}

resource "azurerm_machine_learning_workspace" "serve" {
  name                    = "aml-${var.naming_suffix}"
  location                = var.core_rg_location
  resource_group_name     = var.core_rg_name
  application_insights_id = azurerm_application_insights.serve.id
  key_vault_id            = var.core_kv_id
  storage_account_id      = azurerm_storage_account.aml.id
  tags                    = var.tags

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_private_endpoint.aml_blob
  ]
}

resource "azurerm_container_registry" "serve" {
  name                          = "acrserve${var.naming_suffix_truncated}"
  location                      = var.core_rg_location
  resource_group_name           = var.core_rg_name
  sku                           = "Basic"
  admin_enabled                 = true
  public_network_access_enabled = true
}

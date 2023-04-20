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

resource "azurerm_machine_learning_workspace" "serve" {
  name                          = "aml-${var.naming_suffix}"
  location                      = var.core_rg_location
  resource_group_name           = var.core_rg_name
  application_insights_id       = azurerm_application_insights.serve.id
  key_vault_id                  = var.core_kv_id
  storage_account_id            = azurerm_storage_account.aml.id
  public_network_access_enabled = false
  # container_registry_id         =  TODO? 
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_private_endpoint.aml_blob
  ]
}



resource "azurerm_role_assignment" "data_scientists_can_use_registry" {
  scope              = azurerm_machine_learning_workspace.aml_workspace.id
  role_definition_id = data.azurerm_role_definition.azure_ml_data_scientist.id
  principal_id       = var.data_scientists_ad_group_principal_id
}

# role for data scientists to push models

# aml model registry






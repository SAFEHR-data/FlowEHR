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
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_private_endpoint.aml_blob
  ]
}

resource "local_file" "aml_registry_config" {
  content  = <<EOF
name: ${local.aml_registry_name}
description: Basic AML registry located in ${var.core_rg_location}
location: ${var.core_rg_location}
replication_locations:
  - location: ${var.core_rg_location}
EOF
  filename = "registry.yml"
}

# AML registry usees public network accesss, should be altered when it support private
resource "null_resource" "az_cli_registry_create" {
  provisioner "local-exec" {
    when = create
    command = "az ml registry create --file ${local_file.aml_registry_config.filename} --resource-group ${var.core_rg_name} --public-network-access Enabled"
  }
}

resource "null_resource" "az_cli_registry_create_destroy" {
  triggers = {
    core_rg_name = var.core_rg_name
    aml_registry_name = local.aml_registry_name
  }
  provisioner "local-exec" {
    when = destroy
    command = "az ml registry delete --name ${self.triggers.aml_registry_name} --resource-group ${self.triggers.core_rg_name}"
  }
}

resource "azurerm_role_definition" "aml_registry_read_write" {
  name        = "role-aml-registry-read-write-${var.naming_suffix}"
  scope       = local.aml_registry_id
  description = "Read and write from an AML model registry"

  permissions {
    actions = [
      "Microsoft.MachineLearningServices/registries/read",
      # "Microsoft.MachineLearningServices/registries/assets/read",
      "Microsoft.MachineLearningServices/registries/assets/write"
    ]
  }

  assignable_scopes = [
    local.aml_registry_id
  ]

  depends_on = [
    null_resource.az_cli_registry_create
  ]
}

resource "azurerm_role_assignment" "data_scientists_can_use_registry" {
  scope              = local.aml_registry_id
  role_definition_id = replace(azurerm_role_definition.aml_registry_read_write.id, "|", "")
  principal_id       = var.data_scientists_ad_group_principal_id
}

resource "azurerm_machine_learning_compute_cluster" "serve" {
  name                          = "amlcc-serve-${var.naming_suffix}"
  vm_priority                   = "LowPriority"
  vm_size                       = "STANDARD_DS2_V2"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.serve.id
  subnet_resource_id            = azurerm_subnet.aml.id
  location                      = var.core_rg_location

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 1
    scale_down_nodes_after_idle_duration = "PT30S" # 30 seconds
  }

  identity {
    type = "SystemAssigned"
  }
}

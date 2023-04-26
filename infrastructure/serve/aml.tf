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
    when    = create
    command = "az extension add --name ml && az ml registry create --file ${local_file.aml_registry_config.filename} --resource-group ${var.core_rg_name} --public-network-access Enabled"
  }
}

resource "null_resource" "az_cli_registry_create_destroy" {
  triggers = {
    core_rg_name      = var.core_rg_name
    aml_registry_name = local.aml_registry_name
  }
  provisioner "local-exec" {
    when    = destroy
    command = "az extension add --name ml && az ml registry delete --name ${self.triggers.aml_registry_name} --resource-group ${self.triggers.core_rg_name}"
  }
}

resource "azurerm_role_definition" "aml_registry_read_write" {
  name        = "role-aml-registry-read-write-${var.naming_suffix}"
  scope       = local.aml_registry_id
  description = "Read and write from an AML model registry"

  permissions {
    actions = [
      "Microsoft.MachineLearningServices/registries/read",
      "Microsoft.MachineLearningServices/registries/assets/read",
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

resource "azurerm_role_assignment" "algorithm_stewards_can_use_registry" {
  scope              = local.aml_registry_id
  role_definition_id = replace(azurerm_role_definition.aml_registry_read_write.id, "|", "")
  principal_id       = var.algorithm_stewards_ad_group_principal_id
}

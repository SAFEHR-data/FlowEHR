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

resource "azurerm_private_endpoint" "aml_blob" {
  name                = "pe-aml-blob-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  subnet_id           = var.core_subnet_id
  tags                = var.tags

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob-${var.naming_suffix}"
    private_dns_zone_ids = [var.private_dns_zones["blob"].id]
  }

  private_service_connection {
    name                           = "private-service-connection-aml-blob-${var.naming_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.aml.id
    subresource_names              = ["blob"]
  }
}

resource "azurerm_subnet" "aml" {
  name                 = "subnet-aml-${local.naming_suffix}"
  virtual_network_name = var.core_vnet_name
  resource_group_name  = var.core_rg_name
  address_prefixes     = [var.aml_address_space]

  # need to be disabled for AML private compute
  private_endpoint_network_policies_enabled     = false
  private_link_service_network_policies_enabled = false

  service_endpoints = [
    "Microsoft.Storage"
  ]
  service_endpoint_policy_ids = [azapi_resource.aml_service_endpoint_policy.id]
}

resource "azurerm_private_endpoint" "aml" {
  name                = "pe-aml-${local.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  subnet_id           = azurerm_subnet.aml.id
  tags                    = var.tags

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob-${var.naming_suffix}"
    private_dns_zone_ids = [
      var.private_dns_zones["aml"].id,
      var.private_dns_zones["amlcert"].id
    ]
  }

  private_service_connection {
    name                           = "private-service-connection-aml-${var.naming_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_machine_learning_workspace.serve.id
    subresource_names              = ["amlworkspace"]
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.aml,
    azapi_resource.aml_service_endpoint_policy
  ]
}


resource "azurerm_private_endpoint" "file" {
  name                = "pe-file-${local.storage_name}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  subnet_id           = azurerm_subnet.aml.id
  tags                = var.tags

  # TODO


  
  private_dns_zone_group {
    name                 = "dnsgroup-files-${local.storage_name}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.filecore.id]
  }

  private_service_connection {
    name                           = "dnsgroup-file-${var.tre_id}"
    private_connection_resource_id = azurerm_storage_account.aml.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  depends_on = [
    azurerm_private_endpoint.blobpe
  ]

}


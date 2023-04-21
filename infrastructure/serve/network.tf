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
  name                 = "subnet-aml-${var.naming_suffix}"
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

resource "azurerm_network_security_group" "aml" {
  name                = "nsg-aml-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "aml" {
  network_security_group_id = azurerm_network_security_group.aml.id
  subnet_id                 = azurerm_subnet.aml.id
}

resource "azurerm_private_endpoint" "aml" {
  name                = "pe-aml-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  subnet_id           = azurerm_subnet.aml.id
  tags                = var.tags

  private_dns_zone_group {
    name = "private-dns-zone-group-blob-${var.naming_suffix}"
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
  name                = "pe-file-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  subnet_id           = azurerm_subnet.aml.id
  tags                = var.tags

  private_dns_zone_group {
    name                 = "private-dns-zone-group-file-${var.naming_suffix}"
    private_dns_zone_ids = [var.private_dns_zones["file"].id]
  }

  private_service_connection {
    name                           = "private-service-connection-file-${var.naming_suffix}"
    private_connection_resource_id = azurerm_storage_account.aml.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
}

resource "azapi_resource" "aml_service_endpoint_policy" {
  type      = "Microsoft.Network/serviceEndpointPolicies@2022-05-01"
  name      = "aml-service-endpoint-policy-${var.naming_suffix}"
  location  = var.core_rg_location
  parent_id = data.azurerm_resource_group.core.id
  body = jsonencode({
    properties = {
      serviceEndpointPolicyDefinitions = [
        {
          name = "aml-service-endpoint-policy-definition-storage-${var.naming_suffix}"
          properties = {
            service = "Microsoft.Storage"
            serviceResources = [
              azurerm_storage_account.aml.id
            ]
          }
          type = "Microsoft.Network/serviceEndpointPolicies/serviceEndpointPolicyDefinitions"
        },
        {
          name = "aml-service-endpoint-policy-definition-azureml-${var.naming_suffix}"
          properties = {
            service = "Global"
            serviceResources = [
              "/services/Azure/MachineLearning"
            ]
          }
          type = "Microsoft.Network/serviceEndpointPolicies/serviceEndpointPolicyDefinitions"
        }
      ]
    }
  })
}

resource "azurerm_network_security_rule" "allow_inbound_within_core_vnet" {
  access                       = "Allow"
  destination_port_range       = "*"
  destination_address_prefixes = data.azurerm_virtual_network.core.address_space
  source_address_prefixes      = data.azurerm_virtual_network.core.address_space
  direction                    = "Inbound"
  name                         = "inbound-within-workspace-vnet"
  network_security_group_name  = azurerm_network_security_group.aml.name
  priority                     = 100
  protocol                     = "*"
  resource_group_name          = var.core_rg_name
  source_port_range            = "*"
}

resource "azurerm_network_security_rule" "allow_outbound_to_internet" {
  access                      = "Allow"
  destination_address_prefix  = "INTERNET"
  destination_port_range      = "443"
  direction                   = "Outbound"
  name                        = "to-internet"
  network_security_group_name = azurerm_network_security_group.aml.name
  priority                    = 105
  protocol                    = "Tcp"
  resource_group_name         = var.core_rg_name
  source_address_prefix       = "*"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "allow_outbound_to_aml_udp_5831" {
  access                      = "Allow"
  destination_address_prefix  = "AzureMachineLearning"
  destination_port_range      = "5831"
  direction                   = "Outbound"
  name                        = "to-aml-udp"
  network_security_group_name = azurerm_network_security_group.aml.name
  priority                    = 106
  protocol                    = "Udp"
  resource_group_name         = var.core_rg_name
  source_address_prefix       = "*"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "allow_outbound_to_aml_tcp_443" {
  access                      = "Allow"
  destination_address_prefix  = "AzureMachineLearning"
  destination_port_range      = "443"
  direction                   = "Outbound"
  name                        = "to-aml-tcp-443"
  network_security_group_name = azurerm_network_security_group.aml.name
  priority                    = 107
  protocol                    = "Tcp"
  resource_group_name         = var.core_rg_name
  source_address_prefix       = "*"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "allow_outbound_to_aml_tcp_8787" {
  access                      = "Allow"
  destination_address_prefix  = "AzureMachineLearning"
  destination_port_range      = "8787"
  direction                   = "Outbound"
  name                        = "to-aml-tcp-8787-rstudio"
  network_security_group_name = azurerm_network_security_group.aml.name
  priority                    = 108
  protocol                    = "Tcp"
  resource_group_name         = var.core_rg_name
  source_address_prefix       = "*"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "allow_outbound_to_aml_tcp_18881" {
  access                      = "Allow"
  destination_address_prefix  = "AzureMachineLearning"
  destination_port_range      = "18881"
  direction                   = "Outbound"
  name                        = "to-aml-tcp-18881-language-server"
  network_security_group_name = azurerm_network_security_group.aml.name
  priority                    = 109
  protocol                    = "Tcp"
  resource_group_name         = var.core_rg_name
  source_address_prefix       = "*"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "deny_outbound_override" {
  access                      = "Deny"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  direction                   = "Outbound"
  name                        = "deny-outbound-override"
  network_security_group_name = azurerm_network_security_group.aml.name
  priority                    = 4096
  protocol                    = "*"
  resource_group_name         = var.core_rg_name
  source_address_prefix       = "*"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "deny_all_inbound_override" {
  access                      = "Deny"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  direction                   = "Inbound"
  name                        = "deny-inbound-override"
  network_security_group_name = azurerm_network_security_group.aml.name
  priority                    = 4096
  protocol                    = "*"
  resource_group_name         = var.core_rg_name
  source_address_prefix       = "*"
  source_port_range           = "*"
}

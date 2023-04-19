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

resource "random_integer" "ip1" {
  count = var.use_random_address_space ? 1 : 0
  min   = 65
  max   = 69
  keepers = {
    suffix = local.naming_suffix
  }
}

resource "random_integer" "ip2" {
  count = var.use_random_address_space ? 1 : 0
  min   = 0
  max   = 255
  keepers = {
    suffix = local.naming_suffix
  }
}

resource "azurerm_virtual_network" "core" {
  name                = "vnet-${local.naming_suffix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = azurerm_resource_group.core.location
  tags                = var.tags

  address_space = [
    var.use_random_address_space
    ? "10.${random_integer.ip1[0].result}.${random_integer.ip2[0].result}.0/24"
    : var.core_address_space
  ]
}

resource "azurerm_subnet" "core_shared" {
  name                 = "subnet-core-shared-${local.naming_suffix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = [local.core_shared_address_space]
}

resource "azurerm_subnet" "databricks_host" {
  name                 = "subnet-dbks-host-${local.naming_suffix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = [local.databricks_host_address_space]

  delegation {
    name = "dbks-host-vnet-integration"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_subnet" "databricks_container" {
  name                 = "subnet-dbks-container-${local.naming_suffix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = [local.databricks_container_address_space]

  delegation {
    name = "dbks-container-vnet-integration"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_subnet" "serve_webapps" {
  name                                          = "subnet-serve-webapps-${local.naming_suffix}"
  resource_group_name                           = azurerm_resource_group.core.name
  virtual_network_name                          = azurerm_virtual_network.core.name
  private_endpoint_network_policies_enabled     = false
  private_link_service_network_policies_enabled = true
  address_prefixes                              = [local.serve_webapps_address_space]

  delegation {
    name = "web-app-vnet-integration"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "created_zones" {
  for_each            = local.create_dns_zones ? local.required_private_dns_zones : {}
  name                = each.value
  resource_group_name = azurerm_resource_group.core.name
  tags                = var.tags
}

resource "azurerm_virtual_network_peering" "ci_to_flowehr" {
  count                     = var.tf_in_automation ? 1 : 0
  name                      = "peer-ci-to-flwr-${local.naming_suffix}"
  resource_group_name       = var.ci_rg_name
  virtual_network_name      = var.ci_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.core.id
}

resource "azurerm_virtual_network_peering" "flowehr_to_ci" {
  count                     = var.tf_in_automation ? 1 : 0
  name                      = "peer-flwr-${local.naming_suffix}-to-ci"
  resource_group_name       = azurerm_resource_group.core.name
  virtual_network_name      = azurerm_virtual_network.core.name
  remote_virtual_network_id = data.azurerm_virtual_network.ci[0].id
}

# If private_dns_zones_rg isn't set, we link to the created zones, otherwise link to pre-existing zones
resource "azurerm_private_dns_zone_virtual_network_link" "flowehr" {
  for_each              = local.create_dns_zones ? azurerm_private_dns_zone.created_zones : data.azurerm_private_dns_zone.existing_zones
  name                  = "vnl-${each.value.name}-flwr-${local.naming_suffix}"
  resource_group_name   = local.create_dns_zones ? azurerm_resource_group.core.name : var.private_dns_zones_rg
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.core.id
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-${local.naming_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  subnet_id           = azurerm_subnet.core_shared.id
  tags                = var.tags

  private_dns_zone_group {
    name = "private-dns-zone-group-blob-${local.naming_suffix}"
    private_dns_zone_ids = [
      local.create_dns_zones
      ? azurerm_private_dns_zone.created_zones["blob"].id
      : data.azurerm_private_dns_zone.existing_zones["blob"].id
    ]
  }

  private_service_connection {
    name                           = "private-service-connection-blob-${local.naming_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.core.id
    subresource_names              = ["blob"]
  }

  # Wait for all subnet operations to avoid operation conflicts
  depends_on = [
    azurerm_subnet.core_shared,
    azurerm_subnet.databricks_host,
    azurerm_subnet.databricks_container
  ]
}


resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-${local.naming_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  subnet_id           = azurerm_subnet.core_shared.id
  tags                = var.tags

  private_dns_zone_group {
    name = "private-dns-zone-group-kv-${local.naming_suffix}"
    private_dns_zone_ids = [
      local.create_dns_zones
      ? azurerm_private_dns_zone.created_zones["keyvault"].id
      : data.azurerm_private_dns_zone.existing_zones["keyvault"].id
    ]
  }

  private_service_connection {
    name                           = "private-service-connection-kv-${local.naming_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.core.id
    subresource_names              = ["Vault"]
  }

  # Wait for all subnet operations to avoid operation conflicts
  depends_on = [
    azurerm_subnet.core_shared,
    azurerm_subnet.databricks_host,
    azurerm_subnet.databricks_container
  ]
}

resource "azurerm_network_security_group" "core" {
  name                = "nsg-default-${local.naming_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name

  security_rule {
    name                       = "deny-internet-outbound-override"
    description                = "Blocks outbound internet traffic unless an explicit outbound-allow rule exists. Overrides the default rule 65001"
    priority                   = 2000
    access                     = "Deny"
    protocol                   = "*"
    direction                  = "Outbound"
    destination_address_prefix = "Internet"
    destination_port_range     = 443
    source_address_prefix      = "*"
    source_port_range          = "*"
  }
}

resource "azurerm_network_watcher_flow_log" "data_sources" {
  count                     = (var.monitoring.network_watcher != null) || var.accesses_real_data ? 1 : 0
  name                      = "nw-log-${local.naming_suffix}"
  resource_group_name       = var.monitoring.network_watcher.resource_group_name
  network_watcher_name      = var.monitoring.network_watcher.name
  network_security_group_id = azurerm_network_security_group.core.id
  storage_account_id        = azurerm_storage_account.core.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.core.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.core.location
    workspace_resource_id = azurerm_log_analytics_workspace.core.id
    interval_in_minutes   = 10
  }

  lifecycle {
    precondition {
      condition     = !var.accesses_real_data || var.monitoring.network_watcher != null
      error_message = "Network watcher flow logs must be enabled with when accesses_real_data"
    }
  }
}

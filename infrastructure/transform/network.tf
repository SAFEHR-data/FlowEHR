resource "azurerm_network_security_group" "databricks" {
  name                = "nsg-dbks-${var.naming_suffix}"
  resource_group_name = var.core_rg_name
  location            = var.core_rg_location
  tags                = var.tags

  security_rule {
    name                       = "AllowInboundDatabricksWorkerNodesToCluster"
    description                = "Required for worker nodes communication within a cluster."
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowOutboundDatabricksWorkerNodesToControlPlain"
    description                = "Required for workers communication with Databricks Webapp."
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureDatabricks"
  }

  security_rule {
    name                       = "AllowOutboundDatabricksWorkerNodesToAzureSQLServices"
    description                = "Required for workers communication with Azure SQL services."
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Sql"
  }

  security_rule {
    name                       = "AllowOutboundDatabricksWorkerNodesToAzureStorage"
    description                = "Required for workers communication with Azure Storage services."
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
  }

  security_rule {
    name                       = "AllowOutboundDatabricksWorkerNodesWithinACluster"
    description                = "Required for worker nodes communication within a cluster."
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowOutboundWorkerNodesToAzureEventhub"
    description                = "Required for worker communication with Azure Eventhub services."
    priority                   = 104
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9093"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "EventHub"
  }
}

resource "azurerm_subnet" "databricks_host" {
  name                 = "subnet-dbks-host-${var.naming_suffix}"
  resource_group_name  = var.core_rg_name
  virtual_network_name = data.azurerm_virtual_network.core.name
  address_prefixes     = [var.subnet_address_spaces[1]]

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
  name                 = "subnet-dbks-container-${var.naming_suffix}"
  resource_group_name  = var.core_rg_name
  virtual_network_name = data.azurerm_virtual_network.core.name
  address_prefixes     = [var.subnet_address_spaces[2]]

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

resource "azurerm_subnet_network_security_group_association" "databricks_container" {
  subnet_id                 = azurerm_subnet.databricks_container.id
  network_security_group_id = azurerm_network_security_group.databricks.id
}

resource "azurerm_subnet_network_security_group_association" "databricks_host" {
  subnet_id                 = azurerm_subnet.databricks_host.id
  network_security_group_id = azurerm_network_security_group.databricks.id
}

resource "azurerm_private_dns_zone" "databricks" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = var.core_rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "databricks" {
  name                  = "vnl-dbks-${var.naming_suffix}"
  resource_group_name   = var.core_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.databricks.name
  virtual_network_id    = data.azurerm_virtual_network.core.id
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "databricks_control_plane" {
  name                = "pe-dbks-cp-${var.naming_suffix}"
  resource_group_name = var.core_rg_name
  location            = var.core_rg_location
  subnet_id           = var.core_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "private-service-connection-databricks-control-plane-${var.naming_suffix}"
    private_connection_resource_id = azurerm_databricks_workspace.databricks.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-databricks-control-plane-${var.naming_suffix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.databricks.id]
  }
}

resource "azurerm_private_endpoint" "databricks_filesystem" {
  name                = "pe-dbks-fs-${var.naming_suffix}"
  resource_group_name = var.core_rg_name
  location            = var.core_rg_location
  subnet_id           = var.core_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "private-service-connection-databricks-filesystem-${var.naming_suffix}"
    private_connection_resource_id = join("", [azurerm_databricks_workspace.databricks.managed_resource_group_id, "/providers/Microsoft.Storage/storageAccounts/${local.storage_account_name}"])
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-databricks-filesystem-${var.naming_suffix}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blobcore.id]
  }
}
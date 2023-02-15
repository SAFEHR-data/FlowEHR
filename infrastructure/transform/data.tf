data "azurerm_virtual_network" "core" {
  name                = var.core_vnet_name
  resource_group_name = var.core_rg_name
}

data "azurerm_private_dns_zone" "blobcore" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.core_rg_name
}

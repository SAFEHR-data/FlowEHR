data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "core_rg" {
  name = var.core_rg_name
}

data "azurerm_virtual_network" "core_vnet" {
  name                = "vnet-${var.naming_suffix}"
  resource_group_name = data.azurerm_resource_group.core_rg.name
}

data "azurerm_subnet" "shared_subnet" {
  name                 = "subnet-core-shared-${var.naming_suffix}"
  virtual_network_name = data.azurerm_virtual_network.core_vnet.name
  resource_group_name  = data.azurerm_resource_group.core_rg.name
}

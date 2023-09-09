data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "core_rg" {
  name = var.core_rg_name
}

data "azurerm_databricks_workspace" "workspace" {
  name                = var.databricks_workspace_name
  resource_group_name = var.core_rg_name
}

data "azurerm_resource_group" "metastore_rg" {
  name = var.metastore_rg_name
}

data "azapi_resource" "metastore_access_connector" {
  type      = "Microsoft.Databricks/accessConnectors@2022-04-01-preview"
  name      = local.metastore_access_connector_name
  parent_id = data.azurerm_resource_group.metastore_rg.id
}

data "azurerm_storage_account" "metastore_storage_account" {
  name                = var.metastore_storage_account_name
  resource_group_name = var.metastore_rg_name
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

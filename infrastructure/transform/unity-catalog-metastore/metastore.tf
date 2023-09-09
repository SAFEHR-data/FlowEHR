resource "azurerm_resource_group" "metastore" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "databricks_metastore" "metastore" {
  name = var.metastore_name
  storage_root = format("abfss://%s@%s.dfs.core.windows.net/",
    azurerm_storage_container.unity_catalog.name,
  azurerm_storage_account.unity_catalog.name)
  force_destroy = true
}

resource "azapi_resource" "access_connector" {
  type      = "Microsoft.Databricks/accessConnectors@2022-04-01-preview"
  name      = local.metastore_access_connector_name
  location  = azurerm_resource_group.metastore.location
  parent_id = azurerm_resource_group.metastore.id
  identity { type = "SystemAssigned" }
  body = jsonencode({ properties = {} })
}

resource "azurerm_storage_account" "unity_catalog" {
  name                          = var.storage_account_name
  resource_group_name           = azurerm_resource_group.metastore.name
  location                      = azurerm_resource_group.metastore.location
  tags                          = azurerm_resource_group.metastore.tags
  account_tier                  = "Standard"
  account_replication_type      = "GRS"
  is_hns_enabled                = true
  public_network_access_enabled = false
}

resource "azurerm_storage_container" "unity_catalog" {
  name                  = "unity-catalog-container"
  storage_account_name  = azurerm_storage_account.unity_catalog.name
  container_access_type = "private"

  depends_on = [
    azurerm_role_assignment.deployer_contributor
  ]
}

resource "azurerm_role_assignment" "unity_catalogue_can_contribute_to_storage" {
  scope                = azurerm_storage_account.unity_catalog.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.access_connector.identity[0].principal_id
}

resource "azurerm_role_assignment" "deployer_contributor" {
  scope                = azurerm_storage_account.unity_catalog.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

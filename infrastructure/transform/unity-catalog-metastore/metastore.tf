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
  public_network_access_enabled = !var.tf_in_automation

  network_rules {
    bypass         = ["AzureServices"]
    default_action = "Deny"
    ip_rules       = var.tf_in_automation ? null : [var.deployer_ip]
  }
}

resource "azurerm_private_endpoint" "metastore_pe" {
  for_each = {
    "dfs"  = var.private_dns_zones["blob"].id
    "blob" = var.private_dns_zones["dfs"].id
  }
  name                = "pe-uc-${each.key}-${lower(var.naming_suffix)}"
  location            = data.azurerm_resource_group.core_rg.location
  resource_group_name = var.core_rg_name
  subnet_id           = data.azurerm_subnet.shared_subnet.id

  private_service_connection {
    name                           = "uc-${each.key}-${lower(var.naming_suffix)}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.unity_catalog.id
    subresource_names              = [each.key]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-${each.key}-${var.naming_suffix}"
    private_dns_zone_ids = [each.value]
  }
}

resource "azurerm_storage_container" "unity_catalog" {
  name                  = "unity-catalog-container"
  storage_account_name  = azurerm_storage_account.unity_catalog.name
  container_access_type = "private"

  depends_on = [
    azurerm_role_assignment.deployer_contributor,
    azurerm_private_endpoint.metastore_pe,
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

resource "azurerm_private_endpoint" "metastore_storage" {
  for_each = var.metastore_created ? {} : {
    "dfs"  = var.private_dns_zones["blob"].id
    "blob" = var.private_dns_zones["dfs"].id
  }

  name                = "pe-uc-${var.naming_suffix}"
  location            = data.azurerm_resource_group.core_rg.location
  resource_group_name = var.core_rg_name
  subnet_id           = data.azurerm_subnet.shared_subnet.id

  private_service_connection {
    name                           = "uc-${each.key}-${var.naming_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = data.azurerm_storage_account.metastore_storage_account.id
    subresource_names              = [each.key]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-${each.key}-${var.naming_suffix}"
    private_dns_zone_ids = [each.value]
  }
}

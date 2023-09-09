resource "azurerm_private_endpoint" "metastore_storage" {
  name                = "pe-uc-${var.naming_suffix}"
  location            = data.azurerm_resource_group.core_rg.location
  resource_group_name = var.core_rg_name
  subnet_id           = data.azurerm_subnet.shared_subnet.id

  private_service_connection {
    name                           = "uc-blob-${var.naming_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = data.azurerm_storage_account.metastore_storage_account.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob-${var.naming_suffix}"
    private_dns_zone_ids = [var.private_dns_zones["blob"].id]
  }
}

resource "azurerm_databricks_workspace" "transform" {
  name                        = "${var.prefix}-${var.environment}-dbks"
  resource_group_name         = var.core_rg_name
  managed_resource_group_name = "${var.prefix}-${var.environment}-rg-dbks"
  location                    = var.core_rg_location
  sku                         = "standard"
  tags                        = var.tags
}

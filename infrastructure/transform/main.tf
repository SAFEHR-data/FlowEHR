terraform {
  required_version = "1.3.7"

  # In modules we should only specify the min version
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.32"
    }
  }
}

resource "azurerm_databricks_workspace" "transform" {
  name                = "${var.prefix}-${var.environment}-dbks"
  resource_group_name = var.core_rg_name
  location            = var.core_rg_location
  sku                 = "standard"
  tags                = var.tags
}

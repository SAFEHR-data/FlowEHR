resource "azurerm_application_insights" "serve" {
  name                = "${var.prefix}-${var.environment}-aml-ai"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  application_type    = "web"
}

resource "azurerm_storage_account" "serve" {
  name                     = "${var.prefix}${var.environment}amlstrg"
  location                 = var.core_rg_location
  resource_group_name      = var.core_rg_name
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_machine_learning_workspace" "serve" {
  name                    = "${var.prefix}-${var.environment}-aml"
  location                = var.core_rg_location
  resource_group_name     = var.core_rg_name
  application_insights_id = azurerm_application_insights.serve.id
  key_vault_id            = var.core_kv_id
  storage_account_id      = azurerm_storage_account.serve.id

  identity {
    type = "SystemAssigned"
  }
}

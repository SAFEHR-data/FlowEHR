resource "azurerm_linux_web_app" "app" {
  name                = "webapp-${var.app_id}-${var.naming_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.app_service_plan_id

  site_config {}
}

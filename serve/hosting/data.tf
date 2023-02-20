data "azurerm_app_service_plan" "serve" {
  name                = var.app_service_plan_name
  resource_group_name = var.core_rg_name
}

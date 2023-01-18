provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {}
}

resource "azurerm_resource_group" "core" {
  name     = var.rg_name
  location = var.location
}

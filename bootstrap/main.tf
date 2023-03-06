#  Copyright (c) University College London Hospitals NHS Foundation Trust
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

locals {
  naming_suffix           = var.suffix == "" ? "${var.id}-${var.environment}" : var.suffix
  naming_suffix_truncated = substr(replace(replace(local.naming_suffix, "-", ""), "_", ""), 0, 12)
}

data "http" "local_ip" {
  url = "https://api64.ipify.org"
}

resource "azurerm_resource_group" "bootstrap" {
  name     = "rg-mgmt-${local.naming_suffix}"
  location = var.location
}

resource "azurerm_storage_account" "bootstrap" {
  name                     = "stgmgmt${local.naming_suffix_truncated}"
  resource_group_name      = azurerm_resource_group.bootstrap.name
  location                 = azurerm_resource_group.bootstrap.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                 = "tfstate"
  storage_account_name = azurerm_storage_account.bootstrap.name
}

resource "azurerm_container_registry" "bootstrap" {
  name                = "acrmgmt${local.naming_suffix_truncated}"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
  sku                 = "Basic"
  admin_enabled       = true
}

output "naming_suffix" {
  value = local.naming_suffix
}

output "naming_suffix_truncated" {
  value = local.naming_suffix_truncated
}

output "environment" {
  value = var.environment
}

output "mgmt_rg" {
  value = azurerm_resource_group.bootstrap.name
}

output "mgmt_acr" {
  value = azurerm_container_registry.bootstrap.name
}

output "mgmt_storage" {
  value = azurerm_storage_account.bootstrap.name
}

output "deployer_ip_address" {
  value = var.tf_in_automation ? "" : chomp(data.http.local_ip.response_body)
}

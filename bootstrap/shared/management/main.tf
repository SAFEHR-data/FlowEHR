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

variable "naming_suffix" {
  type = string
}

variable "naming_suffix_truncated" {
  type = string
}

variable "location" {
  description = "The Azure region you wish to deploy resources to"
  type        = string

  validation {
    condition     = can(regex("[a-z]+", var.location))
    error_message = "Only lowercase letters allowed"
  }
}

resource "azurerm_resource_group" "management" {
  name     = "rg-mgmt-${var.naming_suffix}"
  location = var.location
}

resource "azurerm_storage_account" "management" {
  name                     = "stgmgmt${var.naming_suffix_truncated}"
  resource_group_name      = azurerm_resource_group.management.name
  location                 = azurerm_resource_group.management.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                 = "tfstate"
  storage_account_name = azurerm_storage_account.management.name
}

resource "azurerm_container_registry" "management" {
  name                = "acrmgmt${var.naming_suffix_truncated}"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  sku                 = "Basic"
  admin_enabled       = true
}

output "rg" {
  value = azurerm_resource_group.management.name
}

output "acr" {
  value = azurerm_container_registry.management.name
}

output "storage" {
  value = azurerm_storage_account.management.name
}

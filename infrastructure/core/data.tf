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

data "azurerm_client_config" "current" {}

data "http" "local_ip" {
  count = var.tf_in_automation ? 0 : 1
  url   = "https://api64.ipify.org"
}

data "azurerm_virtual_network" "ci" {
  count               = var.tf_in_automation ? 1 : 0
  name                = var.ci_vnet_name
  resource_group_name = var.ci_rg_name
}

data "azurerm_private_dns_zone" "existing_zones" {
  for_each            = var.private_dns_zones_rg != null ? local.required_private_dns_zones : {}
  name                = each.value
  resource_group_name = var.private_dns_zones_rg
}

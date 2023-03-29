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

output "naming_suffix" {
  value = local.naming_suffix
}

output "naming_suffix_truncated" {
  value = local.naming_suffix_truncated
}

output "core_rg_name" {
  value = azurerm_resource_group.core.name
}

output "core_rg_location" {
  value = azurerm_resource_group.core.location
}

output "core_vnet_name" {
  value = azurerm_virtual_network.core.name
}

output "core_subnet_id" {
  value = azurerm_subnet.core_shared.id
}

output "core_kv_id" {
  value = azurerm_key_vault.core.id
}

output "core_kv_uri" {
  value = azurerm_key_vault.core.vault_uri
}

output "core_shared_address_space" {
  value = local.core_shared_address_space
}

output "databricks_host_address_space" {
  value = local.databricks_host_address_space
}

output "databricks_container_address_space" {
  value = local.databricks_container_address_space
}

output "serve_webapps_address_space" {
  value = local.serve_webapps_address_space
}

output "core_log_analytics_name" {
  value = azurerm_log_analytics_workspace.core.name
}

output "deployer_ip" {
  value = data.http.local_ip[0].response_body
}

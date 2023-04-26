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

output "databricks_host_subnet_name" {
  value = azurerm_subnet.databricks_host.name
}

output "databricks_container_subnet_name" {
  value = azurerm_subnet.databricks_container.name
}

output "webapps_subnet_id" {
  value = azurerm_subnet.serve_webapps.id
}

output "core_log_analytics_name" {
  value = azurerm_log_analytics_workspace.core.name
}

output "deployer_ip" {
  value = var.tf_in_automation ? "" : data.http.local_ip[0].response_body
}

output "p0_action_group_id" {
  value = azurerm_monitor_action_group.p0.id
}

output "storage_account_name" {
  value = azurerm_storage_account.core.name
}

output "private_dns_zones" {
  value = local.create_dns_zones ? azurerm_private_dns_zone.created_zones : data.azurerm_private_dns_zone.existing_zones
}

output "developers_ad_group_principal_id" {
  description = "Developers AD group principal id"
  value       = var.accesses_real_data ? "" : azuread_group.ad_group_developers[0].object_id
}

output "data_scientists_ad_group_principal_id" {
  description = "Data scientists AD group principal id"
  value       = azuread_group.ad_group_data_scientists.object_id
}

output "developers_ad_group_display_name" {
  description = "Developers AD group display name"
  value       = var.accesses_real_data ? "" : azuread_group.ad_group_developers[0].display_name
}

output "data_scientists_ad_group_display_name" {
  description = "Data scientists AD group display name"
  value       = azuread_group.ad_group_data_scientists.display_name
}

output "algorithm_stewards_ad_group_principal_id" {
  description = "Algorithm Stewards AD group principal id"
  value       = azuread_group.ad_group_algorithm_stewards.object_id
}

output "algorithm_stewards_ad_group_display_name" {
  description = "Algorithm Stewards AD group display name"
  value       = azuread_group.ad_group_algorithm_stewards.display_name
}

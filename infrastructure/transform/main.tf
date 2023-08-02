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

module "datalake" {
  count                      = local.datalake_enabled ? 1 : 0
  source                     = "./datalake"
  naming_suffix              = var.naming_suffix
  core_rg_name               = var.core_rg_name
  core_rg_location           = var.core_rg_location
  core_subnet_id             = var.core_subnet_id
  core_kv_id                 = var.core_kv_id
  private_dns_zones          = var.private_dns_zones
  tf_in_automation           = var.tf_in_automation
  deployer_ip                = var.deployer_ip
  zones                      = var.transform.datalake.zones
  adf_id                     = azurerm_data_factory.adf.id
  adf_identity_object_id     = azurerm_data_factory.adf.identity[0].principal_id
  databricks_adls_app_name   = local.databricks_adls_app_name
  databricks_secret_scope_id = databricks_secret_scope.secrets.id
  tags                       = var.tags
}

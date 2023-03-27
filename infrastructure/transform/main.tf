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
  count                         = var.transform.datalake.enabled ? 1 : 0
  source                        = "./datalake"
  core_rg_name                  = var.core_rg_name
  core_rg_location              = var.core_rg_location
  core_vnet_name                = var.core_vnet_name
  core_subnet_id                = var.core_subnet_id
  core_kv_id                    = var.core_kv_id
  databricks_identity_object_id = azuread_service_principal.flowehr_databricks_adls[0].object_id
  adf_identity_object_id        = azurerm_data_factory.adf.identity[0].principal_id
  zones                         = var.transform.datalake.zones
  tf_in_automation              = var.tf_in_automation
  deployer_ip_address           = var.deployer_ip_address
  naming_suffix                 = var.naming_suffix
  tags                          = var.tags

}

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

  providers = {
    databricks          = databricks
    databricks.accounts = databricks.accounts
  }
}

module "unity_catalog_metastore" {
  count  = local.create_unity_catalog_metastore ? 1 : 0
  source = "./unity-catalog-metastore"

  core_rg_name  = var.core_rg_name
  naming_suffix = var.naming_suffix

  resource_group_name = var.transform.unity_catalog_metastore.resource_group_name
  location            = var.core_rg_location
  tags                = var.tags

  metastore_name                  = var.transform.unity_catalog_metastore.metastore_name
  storage_account_name            = var.transform.unity_catalog_metastore.storage_account_name
  metastore_access_connector_name = "metastore-access-connector"
  private_dns_zones               = var.private_dns_zones
  tf_in_automation                = var.tf_in_automation
  deployer_ip                     = var.deployer_ip

  catalog_admin_group_name          = var.transform.unity_catalog.catalog_admin_group_name
  external_storage_admin_group_name = var.transform.unity_catalog.external_storage_admin_group_name

  providers = {
    databricks          = databricks
    databricks.accounts = databricks.accounts
  }
}

module "unity_catalog" {
  count  = local.unity_catalog_enabled ? 1 : 0
  source = "./unity-catalog"

  core_rg_name  = var.core_rg_name
  naming_suffix = var.naming_suffix

  metastore_id = (
    local.create_unity_catalog_metastore
    ? module.unity_catalog_metastore[0].metastore_id
    : var.transform.unity_catalog_metastore.metastore_id
  )
  metastore_rg_name               = var.transform.unity_catalog_metastore.resource_group_name
  metastore_access_connector_name = "metastore-access-connector"
  metastore_storage_account_name  = var.transform.unity_catalog_metastore.storage_account_name
  metastore_created               = local.create_unity_catalog_metastore

  catalog_name             = var.transform.unity_catalog.catalog_name
  catalog_name_prefix      = var.transform.unity_catalog.catalog_name_prefix
  catalog_admin_group_name = var.transform.unity_catalog.catalog_admin_group_name
  catalog_admin_privileges = var.transform.unity_catalog.catalog_admin_privileges

  schema_name        = var.transform.unity_catalog.schema_name
  schema_name_prefix = var.transform.unity_catalog.schema_name_prefix

  external_storage_admin_group_name = var.transform.unity_catalog.external_storage_admin_group_name
  external_storage_admin_privileges = var.transform.unity_catalog.external_storage_admin_privileges

  databricks_workspace_name  = azurerm_databricks_workspace.databricks.name
  adf_managed_identity_sp_id = databricks_service_principal.adf_managed_identity_sp.id

  external_storage_accounts = [{
    storage_account_id   = module.datalake[0].adls_id
    storage_account_name = module.datalake[0].adls_name
    container_names      = var.transform.unity_catalog.datalake_zones
  }]

  private_dns_zones = var.private_dns_zones

  providers = {
    databricks          = databricks
    databricks.accounts = databricks.accounts
  }
  depends_on = [azurerm_databricks_workspace.databricks, module.unity_catalog_metastore]
}

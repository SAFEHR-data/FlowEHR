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

variable "databricks_workspace_name" {
  description = "Name of the Azure Databricks Workspace"
  type        = string
}

variable "core_rg_name" {
  description = "Name of the Core Resource Group that Databricks Workspace is deployed to"
  type        = string
}

variable "naming_suffix" {
  description = "Naming suffix used to name all FlowEHR resources"
  type        = string
}

variable "catalog_name" {
  description = "Name to use for Catalog in Unity Catalog"
  type        = string
}

variable "catalog_name_prefix" {
  description = "Name to use for Catalog in Unity Catalog. The actual name will have suffix of var.naming_suffix. Useful in CI"
  type        = string
}

variable "metastore_rg_name" {
  description = "Name of the Resoure Group that Databricks Metastore was deployed to"
  type        = string
}

variable "metastore_id" {
  description = "Metastore ID (created once per region)"
  type        = string
}

variable "metastore_access_connector_name" {
  description = "Name of the Metastore Access Connector created in unity-catalog-metastore module"
  type        = string
}

variable "metastore_storage_account_name" {
  description = "Name of the storage account created for Metastore"
  type        = string
}

variable "metastore_created" {
  description = "Whether Databricks Metastore is created as a part of the same FlowEHR deployment"
  type        = bool
}

variable "schema_name" {
  description = "Schema name to use in Unity Catalog. Needs to be unique witin the metastore"
  type        = string
}

variable "schema_name_prefix" {
  description = "Name to use for Schema in Unity Catalog. The actual name will have suffix of var.naming_suffix. Useful in CI"
  type        = string
}

variable "catalog_admin_group_name" {
  description = "Name of the Catalog Admin group. The group is created during the deployment of Unity Catalog Metastore."
  type        = string
}

variable "catalog_admin_privileges" {
  description = "Admin privileges for Catalog Admin group. Defaults to ALL_PRIVILEGES"
  type        = list(string)
}

variable "external_storage_admin_group_name" {
  description = "Name of the External Storage Admin group. The group is created during the deployment of Unity Catalog Metastore."
  type        = string
}

variable "external_storage_admin_privileges" {
  description = "Admin privileges for Catalog Admin group. Defaults to ALL_PRIVILEGES"
  type        = list(string)
}

variable "external_storage_accounts" {
  description = "External Storage Accounts to give Unity Catalog access to"
  type = list(object({
    storage_account_id   = string
    storage_account_name = string
    container_names      = list(string)
  }))
}

variable "private_dns_zones" {
  description = "Private DNS zones created for the Core group"
  type        = map(any)
}

variable "adf_managed_identity_sp_id" {
  description = "Application ID of the Service Principal"
  type        = string
}

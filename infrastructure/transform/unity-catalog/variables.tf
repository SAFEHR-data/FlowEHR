variable "databricks_workspace_name" {
  description = "Name of the Azure Databricks Workspace"
}

variable "core_rg_name" {
  description = "Name of the Core Resource Group that Databricks Workspace is deployed to"
}

variable "naming_suffix" {
  description = "Naming suffix used to name all FlowEHR resources"
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

variable "catalog_admin_group_name" {
  type = string
}

variable "catalog_admin_privileges" {
  type = list(string)
}

variable "schema_name" {
  type = string
}

variable "schema_name_prefix" {
  description = "Name to use for Schema in Unity Catalog. The actual name will have suffix of var.naming_suffix. Useful in CI"
  type        = string
}

variable "external_storage_admin_group_name" {
  type = string
}

variable "external_storage_admin_privileges" {
  type = list(string)
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
  type = map(any)
}

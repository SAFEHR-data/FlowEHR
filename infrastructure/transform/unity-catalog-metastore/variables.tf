
/* default_metastore_workspace_id = local.databricks_workspace_id
  default_metastore_default_catalog_name = var.catalog_name */

// variable "default_metastore_workspace_id" {}

variable "resource_group_name" {}

variable "location" {}

variable "tags" {}

variable "metastore_name" {
  default = "metastore"
}

variable "storage_account_name" {}

variable "default_metastore_workspace_id" {}

variable "metastore_access_connector_name" {
  type    = string
  default = "metastore-access-connector"
}

variable "tf_in_automation" {
  type = bool
}
variable "deployer_ip" {
  type = string
}

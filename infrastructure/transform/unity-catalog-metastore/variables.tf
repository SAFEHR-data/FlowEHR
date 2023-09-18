variable "resource_group_name" {
  description = "Name for the resource group to create for Unity Catalog Metastore resources"
}

variable "location" {
  description = "Location to use for Unity Catalog Metastore resources"
}

variable "tags" {}

variable "metastore_name" {
  default = "metastore"
}

variable "storage_account_name" {
  description = "Storage account name to use for Unity Catalog Metastore. Must be globally unique"
}

variable "metastore_access_connector_name" {
  type    = string
  default = "metastore-access-connector"
}

variable "core_rg_name" {
  description = "Name of the Core Resource Group"
}

variable "naming_suffix" {
  description = "Naming suffix used to name all FlowEHR resources"
}

variable "tf_in_automation" {
  type = bool
}
variable "deployer_ip" {
  type = string
}

variable "private_dns_zones" {
  type = map(any)
}


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

variable "resource_group_name" {
  type        = string
  description = "Resource group name in which to create Metastore resources."
}

variable "location" {
  type        = string
  description = "Location in which to create Unity Catalog Metastore. One Metastore is allowed per region"
}

variable "tags" {
  type = map(any)
}

variable "metastore_name" {
  type        = string
  default     = "metastore"
  description = "Name for the Unity Catalog Metastore to create. When provided, a new metastore is created."
}

variable "storage_account_name" {
  type        = string
  description = "Name for the Storage Account in which to store Metastore data. Must be globally unique"
}

variable "metastore_access_connector_name" {
  type        = string
  default     = "metastore-access-connector"
  description = "Name of the Metastore Access Connector. Must be the same as is set in unity-catalog module."
}

variable "core_rg_name" {
  description = "Name of the Core Resource Group"
}

variable "naming_suffix" {
  description = "Naming suffix used to name all FlowEHR resources"
}

variable "catalog_admin_group_name" {
  description = "Name of the External Storage Admin group. The group will be created as part of this module."
  type        = string
}

variable "external_storage_admin_group_name" {
  description = "Name of the Catalog Admin group. The group will be created as part of this module."
  type        = string
}

variable "private_dns_zones" {
  type = map(any)
}

variable "tf_in_automation" {
  type = bool
}

variable "deployer_ip" {
  type = string
}

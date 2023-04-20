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

variable "naming_suffix" {
  type = string
}

variable "naming_suffix_truncated" {
  type = string
}

variable "databricks_host_subnet_name" {
  type = string
}

variable "databricks_container_subnet_name" {
  type = string
}

variable "tags" {
  type = map(any)
}

variable "core_rg_name" {
  type = string
}

variable "core_rg_location" {
  type = string
}

variable "core_vnet_name" {
  type = string
}

variable "core_subnet_id" {
  type = string
}

variable "core_kv_id" {
  type = string
}

variable "deployer_ip" {
  type = string
}

variable "tf_in_automation" {
  type = bool
}

variable "p0_action_group_id" {
  type = string
}

variable "core_storage_account_name" {
  type = string
}

variable "accesses_real_data" {
  type    = bool
  default = false
}

variable "private_dns_zones" {
  type = map(any)
}

variable "private_dns_zones_rg" {
  type    = string
  default = null
}

variable "developers_ad_group_display_name" {
  type = string
}

variable "data_scientists_ad_group_display_name" {
  type = string
}

variable "access_databricks_management_publicly" {
  type        = bool
  description = "Whether to allow access to the Databricks workspace management plane via a public network"
  default     = true
}

variable "transform" {
  description = "Transform configuration block (populated from root config file)"
  type = object({
    spark_version = optional(string, "3.3.1")
    repositories = optional(list(object({
      url = string,
      sha = optional(string, "")
    })), [])
  })
  default = {
    spark_version = "3.3.1"
    repositories  = []
  }
}

variable "data_source_connections" {
  description = "List of data sources for the transform pipeline"
  type = list(object({
    name     = string
    fqdn     = string
    database = string
    username = string
    password = string
    peering = optional(
      object({
        virtual_network_name = string
        resource_group_name  = string
        dns_zones            = optional(list(string), [])
      })
    )
  }))
  default = []
}

variable "monitoring" {
  description = "Monitoring block"
  type        = any # Type validated in core
  default = {
    alert_recipients = []
  }
}

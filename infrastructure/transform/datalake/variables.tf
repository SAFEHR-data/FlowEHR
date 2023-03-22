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

variable "zones" {
  description = "zones"
  type = list(object({
    name = string
    containers = optional(list(object({
      name = string
    })), [])
    })
  )
}

variable "tags" {
  type = map(any)
}

variable "naming_suffix" {
  type = string
}

variable "tf_in_automation" {
  type = bool
}

variable "deployer_ip_address" {
  type = string
}

variable "databricks_identity_object_id" {
  type = string
}

variable "adf_identity_object_id" {
  type = string
}

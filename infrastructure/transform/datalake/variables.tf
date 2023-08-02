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

variable "core_rg_name" {
  type = string
}

variable "core_rg_location" {
  type = string
}

variable "core_subnet_id" {
  type = string
}

variable "core_kv_id" {
  type = string
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

variable "zones" {
  description = "Datalake zones to deploy"
  type        = set(string)
}

variable "adf_id" {
  type = string
}

variable "adf_identity_object_id" {
  type = string
}

variable "databricks_adls_app_name" {
  type = string
}

variable "databricks_secret_scope_id" {
  type = string
}

variable "tags" {
  type = map(any)
}

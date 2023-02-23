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

variable "local_mode" {
  type = bool
}

variable "app_id" {
  type = string
}

variable "naming_suffix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "webapps_subnet_id" {
  type = string
}

variable "log_analytics_name" {
  type = string
}

variable "acr_name" {
  type = string
}

variable "app_service_plan_name" {
  type = string
}

variable "cosmos_account_name" {
  type = string
}

variable "feature_store_db_name" {
  type = string
}

variable "feature_store_server_name" {
  type = string
}

variable "app_config" {
  type = object({
    name        = string
    description = string
    owner       = string

    contributors = list(object({
      email       = string
      gh_username = string
    }))

    managed_repo = object({
      template         = string,
      branch_approvers = list(string)
    })

    env = optional(map(string))
  })
}

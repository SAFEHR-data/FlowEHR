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

variable "environment" {
  type = string
}

variable "suffix_override" {
  type = string
}

variable "tf_in_automation" {
  type = bool
}

variable "core_rg_name" {
  type = string
}

variable "core_rg_location" {
  type = string
}

variable "core_log_analytics_name" {
  type = string
}

variable "transform_feature_store_db_name" {
  type = string
}

variable "transform_apps_ad_group_principal_id" {
  type = string
}

variable "core_developers_ad_group_principal_id" {
  type = string
}

variable "core_data_scientists_ad_group_principal_id" {
  type = string
}

variable "transform_feature_store_server_name" {
  type = string
}

variable "serve_app_service_plan_name" {
  type = string
}

variable "serve_cosmos_account_name" {
  type = string
}

variable "serve_acr_name" {
  type = string
}

variable "serve_webapps_subnet_id" {
  type = string
}

variable "github_app_cert" {
  description = "GitHub App Private Key PEM file contents as string"
  type        = string
  sensitive   = true
}

# -- FROM CONFIGURATION FILES --------
variable "accesses_real_data" {
  type    = bool
  default = false
}

variable "serve" {
  description = "Serve configuration block (populated from root config file(s)). Required when apps are configured for deployment."
  type = object({
    github_owner               = string
    github_app_id              = string
    github_app_installation_id = string
  })
  # Set a default so a serve block isn't required when running make all without any apps configured
  default = {
    github_owner               = null
    github_app_id              = null
    github_app_installation_id = null
  }
}

variable "apps" {
  description = "Apps configuration file containing the apps to deploy"
  type = map(object({
    name             = string
    description      = optional(string, "Created by FlowEHR")
    add_testing_slot = optional(bool, false)
    require_auth     = optional(bool, true)
    owners           = map(string)
    contributors     = map(string)

    managed_repo = optional(object({
      private  = bool
      template = string
    }))

    branch = optional(object({
      num_of_approvals      = optional(number, 1),
      dismiss_stale_reviews = optional(bool, false)
      }), {
      num_of_approvals      = 1
      dismiss_stale_reviews = false
    })

    env = optional(map(string))
  }))
}

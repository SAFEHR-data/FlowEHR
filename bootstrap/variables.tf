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

variable "suffix" {
  description = "Unique value for differentiating organisations/projects"
  type        = string

  validation {
    condition     = length(var.suffix) < 7
    error_message = "Must be less than 7 chars"
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\_-]*$", var.suffix))
    error_message = "Cannot contain spaces or special characters except '-' and '_'"
  }
}

variable "environment" {
  description = "Environment name for differentiating deployment environments"
  type        = string

  validation {
    condition     = length(var.environment) < 7
    error_message = "Must be less than 7 chars"
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\_-]*$", var.environment))
    error_message = "Cannot contain spaces or special characters except '-' and '_'"
  }
}

variable "location" {
  description = "The Azure region you wish to deploy resources to"
  type        = string

  validation {
    condition     = can(regex("[a-z]+", var.location))
    error_message = "Only lowercase letters allowed"
  }
}

variable "tf_in_automation" {
  description = "Whether Terraform is being run in CI or locally. Local mode will whitelist deployer ip on certain resources to enable deployment outside of vnet."
  type        = bool
}

variable "suffix_override" {
  description = "Override the standard suffix that would be created from suffix + environment. Useful for transient PR environments"
  type        = string
}

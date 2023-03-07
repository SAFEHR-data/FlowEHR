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

variable "id" {
  description = "Unique value for differentiating FlowEHR deployments across organisations/projects"
  type        = string

  validation {
    condition     = length(var.id) < 10
    error_message = "Must be less than 10 chars"
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\_-]*$", var.id))
    error_message = "Cannot contain spaces or special characters except '-' and '_'"
  }
}

variable "environment" {
  description = "Environment name for differentiating deployment environments"
  type        = string

  validation {
    condition     = length(var.environment) < 10
    error_message = "Must be less than 10 chars"
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

variable "suffix" {
  description = "Override the suffix that would be generated from id + environment. Useful for transient PR environments"
  type        = string
  default     = ""
}

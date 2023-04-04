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

variable "flowehr_id" {
  description = "Unique value for differentiating FlowEHR deployments across organisations/projects"
  type        = string

  validation {
    condition     = length(var.flowehr_id) <= 12
    error_message = "Must be 12 chars or less"
  }

  validation {
    condition     = can(regex("^[a-z0-9\\_-]*$", var.flowehr_id))
    error_message = "Cannot contain spaces, uppercase or special characters except '-' and '_'"
  }
}

variable "environment" {
  description = "Environment name for differentiating deployment environments"
  type        = string

  validation {
    condition     = length(var.environment) <= 12
    error_message = "Must be 12 chars or less"
  }

  validation {
    condition     = can(regex("^[a-z0-9\\_-]*$", var.environment))
    error_message = "Cannot contain spaces, uppercase or special characters except '-' and '_'"
  }
}

variable "location" {
  description = "The location to deploy resources"
  type        = string

  validation {
    condition     = can(regex("[a-z]+", var.location))
    error_message = "Only lowercase letters allowed"
  }
}

variable "suffix_override" {
  description = "Override the suffix that would be generated from id + environment. Useful for transient PR environments"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9\\_-]*$", var.suffix_override))
    error_message = "Cannot contain spaces, uppercase or special characters except '-' and '_'"
  }
}

variable "tags" {
  type = map(any)
}

variable "core_address_space" {
  type        = string
  description = "The CIDR address space for the core virtual network (must be /24 or wider)"
  default     = "10.0.0.0/24"
}

variable "use_random_address_space" {
  type        = bool
  description = <<EOF
Whether to randomise the core address space (if set to true this will override the core_address_space variable).
Use for PR/transient environments that peer with other static vnets (i.e. data sources) to reduce chance of conflicts."
EOF
  default     = false
}

variable "ci_vnet_name" {
  description = "Name of the CI bootstrapping vnet to peer with for deployment of data-plane resources"
  type        = string
}

variable "ci_rg_name" {
  description = "Name of the CI bootstrapping resource group"
  type        = string
}

variable "tf_in_automation" {
  type = bool
}

variable "accesses_real_data" {
  type        = bool
  description = "Does this deployment access real data? I.e. is this a staging/production environment?"
}

variable "create_dns_zones" {
  description = <<EOF
Should FlowEHR create private DNS zones required by private links? Set to false if FlowEHR will be peered to a
vnet that already contains the required zones, in which case it will establish a virtual network link to these
existing zones instead.
EOF
  type        = bool
  default     = true
}

variable "dns_zones_rg" {
  description = <<EOF
If create_dns_zones is false, which resource group to look for existing zones in (if not specified,
FlowEHR will search your subscription and fail if there's more than one of the same zone).
EOF
  type        = string
  default     = ""
}

variable "alert_recipients" {
  description = "List of recipients to receive alerts"
  type = list(object({
    name  = string
    email = string
  }))
  default = []
}

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
  type        = string
  description = "Suffix used to name resources"
}

variable "naming_suffix_truncated" {
  type        = string
  description = "Truncated (max 20 chars, no hyphens etc.) suffix to name e.g storage accounts"
}

variable "location" {
  type        = string
  description = "The location to deploy resources"
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
}

variable "deployer_ip_address" {
  type    = string
  default = ""
}

variable "tf_in_automation" {
  type = bool
}

variable "devcontainer_acr_name" {
  type        = string
  description = "Name of the azure container registry i.e. <acr-name>.azurecr.io"
}

variable "devcontainer_tag" {
  type        = string
  description = ""
}

variable "devcontainer_image_name" {
  type        = string
  description = "Name of the azure container registry i.e. aregistry.azurecr.io/<image-name>:tag"
}

variable "github_runner_name" {
  type        = string
  description = "Name of the GitHub runner that will be created"
}

variable "github_runner_token" {
  type        = string
  description = "GitHub token with permissions to register a runner on this repository"
}

variable "github_repository" {
  type        = string
  description = "Github repository in which to create the build agent. e.g. UCLH-Foundry/FlowEHR"
}

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
  type = string
}

variable "location" {
  type = string
}

variable "tf_in_automation" {
  type = bool

  validation {
    condition     = !var.tf_in_automation
    error_message = "CI bootstrapping should be ran locally to create credentials & resources for CI. Please run this from a local machine as a user with rights to assign AD roles."
  }
}

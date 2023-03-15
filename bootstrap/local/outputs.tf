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

output "naming_suffix" {
  value = module.naming.suffix
}

output "naming_suffix_truncated" {
  value = module.naming.suffix_truncated
}

output "environment" {
  value = var.environment
}

output "mgmt_rg" {
  value = var.tf_in_automation ? "" : module.management[0].rg
}

output "mgmt_acr" {
  value = var.tf_in_automation ? "" : module.management[0].acr
}

output "mgmt_storage" {
  value = var.tf_in_automation ? "" : module.management[0].storage
}

output "deployer_ip_address" {
  value = var.tf_in_automation ? "" : chomp(data.http.local_ip[0].response_body)
}

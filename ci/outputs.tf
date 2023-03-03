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

output "ARM_CLIENT_ID" {
  value = azuread_application.ci_app.application_id
}

output "ARM_CLIENT_SECRET" {
  value     = azuread_application_password.ci_app.value
  sensitive = true
}

output "ARM_TENANT_ID" {
  value = data.azurerm_client_config.current.tenant_id
}

output "ARM_SUBSCRIPTION_ID" {
  value = data.azurerm_client_config.current.subscription_id
}

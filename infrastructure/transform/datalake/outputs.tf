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

output "adls_name" {
  value = azurerm_storage_account.adls.name
}

output "databricks_adls_app_id" {
  value = azuread_application.databricks_adls.application_id
}

output "databricks_adls_app_secret_key" {
  value = databricks_secret.databricks_adls_spn_app_secret.key
}

output "databricks_adls_uri_secret_key" {
  value = databricks_secret.adls_uri.key
}

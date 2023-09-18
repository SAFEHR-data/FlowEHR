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

locals {
  # Example value: [ { "storage_account_id" = "...", "storage_account_name" = "stgtest1", "container_name" = "bronze" } ]
  external_storage_locations = flatten([
    for account in var.external_storage_accounts : [
      for container in account.container_names : {
        storage_account_id   = account.storage_account_id
        storage_account_name = account.storage_account_name
        container_name       = container
      }
    ]
  ])

  external_access_connector_name_prefix = "external-access-connector-"
  azapi_access_connector                = "Microsoft.Databricks/accessConnectors@2022-04-01-preview"
}

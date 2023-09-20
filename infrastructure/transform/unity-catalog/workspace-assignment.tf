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

resource "databricks_metastore_assignment" "workspace_assignment" {
  workspace_id = data.azurerm_databricks_workspace.workspace.workspace_id
  metastore_id = var.metastore_id

  depends_on = [databricks_metastore_data_access.metastore_data_access]
}

resource "databricks_metastore_data_access" "metastore_data_access" {
  metastore_id = var.metastore_id
  name         = "dbks-metastore-access-${var.naming_suffix}"

  azure_managed_identity {
    access_connector_id = data.azapi_resource.metastore_access_connector.id
  }

  is_default = var.metastore_created
}

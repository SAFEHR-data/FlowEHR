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

resource "databricks_catalog" "catalog" {
  depends_on   = [databricks_metastore_assignment.workspace_assignment]
  metastore_id = var.metastore_id
  name         = try(var.catalog_name, null) != null ? var.catalog_name : "${var.catalog_name_prefix}_${replace(var.naming_suffix, "-", "")}"
}

resource "databricks_grants" "catalog" {
  depends_on = [databricks_metastore_assignment.workspace_assignment]
  catalog    = databricks_catalog.catalog.name
  grant {
    principal  = data.databricks_group.catalog_admins.display_name
    privileges = var.catalog_admin_privileges
  }
}

resource "databricks_schema" "schema" {
  depends_on   = [databricks_catalog.catalog]
  catalog_name = databricks_catalog.catalog.name
  name         = try(var.schema_name, null) != null ? var.schema_name : "${var.schema_name_prefix}_${replace(var.naming_suffix, "-", "")}"
}

resource "databricks_group_member" "adf_mi_is_catalog_admin" {
  provider  = databricks.accounts
  group_id  = data.databricks_group.catalog_admins.id
  member_id = var.adf_managed_identity_sp_id
}

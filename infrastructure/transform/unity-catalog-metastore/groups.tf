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

resource "databricks_group" "catalog_admin" {
  provider                   = databricks.accounts
  display_name               = var.catalog_admin_group_name
  allow_cluster_create       = true
  allow_instance_pool_create = true
}

resource "databricks_group" "external_storage_admin" {
  provider                   = databricks.accounts
  display_name               = var.external_storage_admin_group_name
  allow_cluster_create       = true
  allow_instance_pool_create = true
}

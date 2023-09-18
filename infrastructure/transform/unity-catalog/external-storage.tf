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

resource "azapi_resource" "ext_access_connector" {
  type      = "Microsoft.Databricks/accessConnectors@2022-04-01-preview"
  name      = "${local.external_access_connector_name_prefix}-${var.naming_suffix}"
  location  = data.azurerm_resource_group.core_rg.location
  parent_id = data.azurerm_resource_group.core_rg.id
  identity { type = "SystemAssigned" }
  body                      = jsonencode({ properties = {} })
  schema_validation_enabled = false
}

resource "databricks_storage_credential" "external" {
  depends_on = [databricks_metastore_assignment.workspace_assignment ]
  name = azapi_resource.ext_access_connector.name
  azure_managed_identity {
    access_connector_id = azapi_resource.ext_access_connector.id
  }
}

resource "azurerm_role_assignment" "external_storage" {
  for_each = { for location in local.external_storage_locations :
    "${location.storage_account_name}:${location.container_name}" => location
  }
  scope                = each.value.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.ext_access_connector.identity[0].principal_id
}

resource "databricks_external_location" "external_location" {
  for_each = { for location in local.external_storage_locations :
    "${location.storage_account_name}:${location.container_name}" => location
  }

  name = "external-${replace(each.key, ":", "-")}"
  url = format("abfss://%s@%s.dfs.core.windows.net/",
    each.value.container_name,
  each.value.storage_account_name)
  credential_name = databricks_storage_credential.external.id

  depends_on = [
    azurerm_role_assignment.external_storage
  ]
}

resource "databricks_grants" "external_storage_credential" {
  depends_on         = [databricks_metastore_assignment.workspace_assignment]
  storage_credential = databricks_storage_credential.external.id
  grant {
    principal  = data.databricks_group.external_storage_admins.display_name
    privileges = var.external_storage_admin_privileges
  }
}

resource "databricks_grants" "external_storage" {
  for_each = { for location in local.external_storage_locations :
    "${location.storage_account_name}:${location.container_name}" => location
  }

  external_location = databricks_external_location.external_location[each.key].id
  grant {
    principal  = data.databricks_group.external_storage_admins.display_name
    privileges = var.external_storage_admin_privileges
  }
}

resource "databricks_group_member" "adf_mi_is_external_storage_admin" {
  provider  = databricks.accounts
  group_id  = data.databricks_group.external_storage_admins.id
  member_id = var.adf_managed_identity_sp_id
}

resource "databricks_metastore_assignment" "workspace_assignment" {
  workspace_id = data.azurerm_databricks_workspace.workspace.workspace_id
  metastore_id = var.metastore_id
}

resource "databricks_metastore_data_access" "metastore_data_access" {
  depends_on   = [databricks_metastore_assignment.workspace_assignment]
  metastore_id = var.metastore_id
  name         = "dbks-metastore-access-${var.naming_suffix}"
  azure_managed_identity {
    access_connector_id = data.azapi_resource.metastore_access_connector.id
  }

  is_default = var.assign_default_workspace
}

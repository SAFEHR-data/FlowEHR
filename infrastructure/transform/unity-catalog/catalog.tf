resource "databricks_catalog" "catalog" {
  depends_on   = [databricks_metastore_assignment.workspace_assignment]
  metastore_id = var.metastore_id
  name         = try(var.catalog_name, null) != null ? var.catalog_name : "${var.catalog_name_prefix}-${var.naming_suffix}"
}

resource "databricks_grants" "catalog" {
  depends_on = [databricks_metastore_assignment.workspace_assignment]
  catalog    = databricks_catalog.catalog.name
  grant {
    principal  = var.external_storage_admin_group_name
    privileges = var.catalog_admin_privileges
  }
}

resource "databricks_schema" "schema" {
  depends_on   = [databricks_catalog.catalog]
  catalog_name = databricks_catalog.catalog.name
  name         = try(var.schema_name, null) != null ? var.schema_name : "${var.schema_name_prefix}-${var.naming_suffix}"
}

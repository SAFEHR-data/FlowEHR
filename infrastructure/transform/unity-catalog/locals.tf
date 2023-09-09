locals {
  tenant_id       = data.azurerm_client_config.current.tenant_id
  subscription_id = data.azurerm_client_config.current.subscription_id

  databricks_workspace_host = data.azurerm_databricks_workspace.workspace.workspace_url
  databricks_workspace_id   = data.azurerm_databricks_workspace.workspace.workspace_id

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

  external_access_connector_name = "external-access-connector"
  # Must match the value in unity-catalog-metastore module
  metastore_access_connector_name = "metastore-access-connector"
}

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

module "datalake" {
  count                         = var.transform.datalake.enabled ? 1 : 0
  source                        = "./datalake"
  core_rg_name                  = var.core_rg_name
  core_rg_location              = var.core_rg_location
  core_vnet_name                = var.core_vnet_name
  core_subnet_id                = var.core_subnet_id
  core_kv_id                    = var.core_kv_id
  databricks_identity_object_id = azuread_service_principal.flowehr_databricks_adls[0].object_id
  adf_identity_object_id        = azurerm_data_factory.adf.identity[0].principal_id
  zones                         = var.transform.datalake.zones
  tf_in_automation              = var.tf_in_automation
  deployer_ip_address           = var.deployer_ip_address
  naming_suffix                 = var.naming_suffix
  tags                          = var.tags

}

resource "azurerm_databricks_workspace" "databricks" {
  name                                  = "dbks-${var.naming_suffix}"
  resource_group_name                   = var.core_rg_name
  managed_resource_group_name           = "rg-dbks-${var.naming_suffix}"
  location                              = var.core_rg_location
  sku                                   = "premium"
  infrastructure_encryption_enabled     = true
  public_network_access_enabled         = var.access_databricks_management_publicly
  network_security_group_rules_required = "NoAzureDatabricksRules"
  tags                                  = var.tags

  custom_parameters {
    no_public_ip                                         = true
    storage_account_name                                 = local.storage_account_name
    public_subnet_name                                   = azurerm_subnet.databricks_host.name
    private_subnet_name                                  = azurerm_subnet.databricks_container.name
    virtual_network_id                                   = data.azurerm_virtual_network.core.id
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.databricks_host.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.databricks_container.id
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.databricks_host,
    azurerm_subnet_network_security_group_association.databricks_container
  ]
}

data "databricks_spark_version" "latest_lts" {
  spark_version = var.transform.spark_version
  depends_on    = [azurerm_databricks_workspace.databricks]
}

data "databricks_node_type" "smallest" {
  # Providing no required configuration, Databricks will pick the smallest node possible
  depends_on = [azurerm_databricks_workspace.databricks]
}

resource "databricks_cluster" "fixed_single_node" {
  cluster_name            = "Fixed Job Cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 10

  spark_conf = merge(
    tomap({
      "spark.databricks.cluster.profile" = "singleNode"
      "spark.master"                     = "local[*]"
      // Secrets for Feature store
      // Formatted according to syntax for referencing secrets in Spark config:
      // https://learn.microsoft.com/en-us/azure/databricks/security/secrets/secrets
      "spark.secret.feature-store-app-id"     = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_spn_app_id.key}}}"
      "spark.secret.feature-store-app-secret" = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_spn_app_secret.key}}}"
      "spark.secret.feature-store-fqdn"       = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_fqdn.key}}}"
      "spark.secret.feature-store-database"   = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_database.key}}}"
    }),
    // Secrets for each data source
    // Formatted according to syntax for referencing secrets in Spark config:
    // https://learn.microsoft.com/en-us/azure/databricks/security/secrets/secrets
    tomap({ for connection in var.data_source_connections :
      "spark.secret.${connection.name}-fqdn" => "{{secrets/${databricks_secret_scope.secrets.name}/flowehr-dbks-${connection.name}-fqdn}}"
    }),
    tomap({ for connection in var.data_source_connections :
      "spark.secret.${connection.name}-database" => "{{secrets/${databricks_secret_scope.secrets.name}/flowehr-dbks-${connection.name}-database}}"
    }),
    tomap({ for connection in var.data_source_connections :
      "spark.secret.${connection.name}-username" => "{{secrets/${databricks_secret_scope.secrets.name}/flowehr-dbks-${connection.name}-username}}"
    }),
    tomap({ for connection in var.data_source_connections :
      "spark.secret.${connection.name}-password" => "{{secrets/${databricks_secret_scope.secrets.name}/flowehr-dbks-${connection.name}-password}}"
    })
  )

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  depends_on = [
    azurerm_databricks_workspace.databricks,
    azurerm_private_endpoint.databricks_control_plane,
    azurerm_private_endpoint.databricks_filesystem
  ]
}

# databricks secret scope, in-built. Not able to use key vault backed scope due to limitation in databricks:
# https://learn.microsoft.com/en-us/azure/databricks/security/secrets/secret-scopes#--create-an-azure-key-vault-backed-secret-scope-using-the-databricks-cli 
resource "databricks_secret_scope" "secrets" {
  name = "flowehr-secrets"
}

resource "azurerm_data_factory" "adf" {
  name                = "adf-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name

  managed_virtual_network_enabled = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "adf_can_create_clusters" {
  scope                = azurerm_databricks_workspace.databricks.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

resource "azurerm_data_factory_integration_runtime_azure" "ir" {
  name                    = "FlowEHRIntegrationRuntime"
  data_factory_id         = azurerm_data_factory.adf.id
  location                = var.core_rg_location
  virtual_network_enabled = true
  description             = "Integration runtime in managed vnet"
  time_to_live_min        = 5
}

resource "azurerm_role_assignment" "adf_can_access_kv_secrets" {
  scope                = azurerm_databricks_workspace.databricks.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

# Get all directories that have activities.json in them and say that they are pipeline directories
resource "azurerm_data_factory_pipeline" "pipeline" {
  for_each        = local.pipeline_dirs
  name            = "databricks-pipeline-${basename(each.value)}-${var.naming_suffix}"
  data_factory_id = azurerm_data_factory.adf.id
  activities_json = file("${each.value}/${local.activities_file}")

  depends_on = [
    azurerm_data_factory_linked_service_azure_databricks.msi_linked
  ]
}

# Assuming that all artifacts will be built
resource "databricks_dbfs_file" "dbfs_artifact_upload" {
  for_each = { for artifact in local.artifacts : artifact.artifact_path => artifact.pipeline }
  # Source path on local filesystem
  source = each.key
  # Path on DBFS
  path = "/pipelines/${each.value}/${local.artifacts_dir}/${basename(each.key)}"
}

resource "azurerm_data_factory_linked_service_azure_databricks" "msi_linked" {
  name            = local.adb_linked_service_name
  data_factory_id = azurerm_data_factory.adf.id
  description     = "Azure Databricks linked service via MSI"
  adb_domain      = "https://${azurerm_databricks_workspace.databricks.workspace_url}"

  msi_work_space_resource_id = azurerm_databricks_workspace.databricks.id

  existing_cluster_id = databricks_cluster.fixed_single_node.cluster_id
}


resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "msi_linked" {
  count                = var.transform.datalake.enabled ? 1 : 0
  name                 = "ADLSLinkedServiceViaMSI"
  data_factory_id      = azurerm_data_factory.adf.id
  description          = "ADLS Gen2"
  use_managed_identity = true
  url                  = "https://${module.datalake[0].storage_account_name}.dfs.core.windows.net"
}

resource "azurerm_data_factory_linked_service_key_vault" "msi_linked" {
  name            = "KVLinkedServiceViaMSI"
  data_factory_id = azurerm_data_factory.adf.id
  description     = "Key Vault linked service via MSI"
  key_vault_id    = var.core_kv_id
}


# AAD App + SPN for Databricks -> ADLS Access
resource "azuread_application" "flowehr_databricks_adls" {
  count        = var.transform.datalake.enabled ? 1 : 0
  display_name = local.databricks_app_name
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_application_password" "flowehr_databricks_adls" {
  count                 = var.transform.datalake.enabled ? 1 : 0
  application_object_id = azuread_application.flowehr_databricks_adls[0].object_id
}

resource "azuread_service_principal" "flowehr_databricks_adls" {
  count          = var.transform.datalake.enabled ? 1 : 0
  application_id = azuread_application.flowehr_databricks_adls[0].application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

resource "azurerm_key_vault_secret" "flowehr_databricks_adls_spn_app_id" {
  count        = var.transform.datalake.enabled ? 1 : 0
  name         = "flowehr-dbks-adls-app-id"
  value        = azuread_service_principal.flowehr_databricks_adls[0].application_id
  key_vault_id = var.core_kv_id
}

resource "azurerm_key_vault_secret" "flowehr_databricks_adls_spn_app_secret" {
  count        = var.transform.datalake.enabled ? 1 : 0
  name         = "flowehr-dbks-adls-app-secret"
  value        = azuread_application_password.flowehr_databricks_adls[0].value
  key_vault_id = var.core_kv_id
}

resource "databricks_secret" "flowehr_databricks_adls_spn_app_id" {
  count        = var.transform.datalake.enabled ? 1 : 0
  key          = "flowehr-dbks-adls-app-id"
  string_value = azuread_service_principal.flowehr_databricks_adls[0].application_id
  scope        = databricks_secret_scope.secrets.id
}

resource "databricks_secret" "flowehr_databricks_adls_spn_app_secret" {
  count        = var.transform.datalake.enabled ? 1 : 0
  key          = "flowehr-dbks-adls-app-secret"
  string_value = azuread_application_password.flowehr_databricks_adls[0].value
  scope        = databricks_secret_scope.secrets.id
}


resource "databricks_mount" "adls_bronze" {
  for_each   = { for zone in var.transform.datalake.zones : zone.name => zone }
  name       = "adls-data-lake-${lower(each.value.name)}"
  uri        = "abfss://${lower(each.value.name)}@${module.datalake[0].storage_account_name}.dfs.core.windows.net/"
  cluster_id = databricks_cluster.fixed_single_node.cluster_id
  extra_configs = {
    "fs.azure.account.auth.type" : "OAuth",
    "fs.azure.account.oauth.provider.type" : "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "fs.azure.account.oauth2.client.id" : azuread_application.flowehr_databricks_adls[0].application_id,
    "fs.azure.account.oauth2.client.secret" : "{{secrets/${databricks_secret_scope.secrets.name}/${azurerm_key_vault_secret.flowehr_databricks_adls_spn_app_secret[0].name}}}",
    "fs.azure.account.oauth2.client.endpoint" : "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/token",
    "fs.azure.createRemoteFileSystemDuringInitialization" : "false",
  }

  depends_on = [
    module.datalake
  ]
}

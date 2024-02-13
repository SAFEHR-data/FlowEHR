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
    storage_account_name                                 = local.dbfs_storage_account_name
    public_subnet_name                                   = data.azurerm_subnet.databricks_host.name
    private_subnet_name                                  = data.azurerm_subnet.databricks_container.name
    virtual_network_id                                   = data.azurerm_virtual_network.core.id
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.databricks_host.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.databricks_container.id
  }
}

# Allow Databricks network configuration to propagate
resource "time_sleep" "wait_for_databricks_network" {
  create_duration = "180s"

  depends_on = [
    azurerm_databricks_workspace.databricks,
    azurerm_private_endpoint.databricks_control_plane,
    azurerm_private_endpoint.databricks_filesystem,
    azurerm_subnet_route_table_association.databricks_host,
    azurerm_subnet_route_table_association.databricks_container,
    azurerm_subnet_route_table_association.shared
  ]
}

data "databricks_spark_version" "latest" {
  spark_version = var.transform.spark_version
  depends_on = [
    time_sleep.wait_for_databricks_network,
    azurerm_databricks_workspace.databricks
  ]
}

data "databricks_node_type" "node_type" {
  min_memory_gb         = var.transform.databricks_cluster.node_type.min_memory_gb
  min_cores             = var.transform.databricks_cluster.node_type.min_cores
  local_disk_min_size   = var.transform.databricks_cluster.node_type.local_disk_min_size
  category              = var.transform.databricks_cluster.node_type.category
  photon_worker_capable = var.transform.databricks_cluster.runtime_engine == "PHOTON"
  photon_driver_capable = var.transform.databricks_cluster.runtime_engine == "PHOTON"

  depends_on = [time_sleep.wait_for_databricks_network]
}

resource "databricks_cluster" "cluster" {
  cluster_name            = "FlowEHR Cluster"
  spark_version           = data.databricks_spark_version.latest.id
  node_type_id            = data.databricks_node_type.node_type.id
  autotermination_minutes = var.transform.databricks_cluster.autotermination_minutes
  num_workers             = !local.autoscale_cluster ? var.transform.databricks_cluster.num_of_workers : null
  runtime_engine          = var.transform.databricks_cluster.runtime_engine
  data_security_mode      = var.transform.databricks_cluster.data_security_mode
  single_user_name        = var.transform.databricks_cluster.data_security_mode == "SINGLE_USER" ? databricks_service_principal.adf_managed_identity_sp.application_id : null

  dynamic "autoscale" {
    for_each = local.autoscale_cluster ? [1] : []

    content {
      min_workers = var.transform.databricks_cluster.autoscale.min_workers
      max_workers = var.transform.databricks_cluster.autoscale.max_workers
    }
  }

  spark_conf = merge(
    # Secrets for SQL Feature store
    # Formatted according to syntax for referencing secrets in Spark config:
    # https://learn.microsoft.com/en-us/azure/databricks/security/secrets/secrets
    tomap({
      "spark.secret.feature-store-app-id"     = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_spn_app_id.key}}}"
      "spark.secret.feature-store-app-secret" = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_spn_app_secret.key}}}"
      "spark.secret.feature-store-fqdn"       = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_fqdn.key}}}"
      "spark.secret.feature-store-database"   = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_database.key}}}"
    }),
    # Secrets for FlowEHR External app
    tomap({
      "spark.secret.azure-tenant-id"               = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.external_connection_azure_tenant_id.key}}}"
      "spark.secret.external-connection-app-id"    = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.external_connection_spn_app_id.key}}}"
      "spark.secret.exernal-connection-app-secret" = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.external_connection_spn_app_secret.key}}}"
    }),
    # MSI connection to Datalake (if enabled)
    var.transform.datalake != null ? tomap({
      "fs.azure.account.auth.type.${module.datalake[0].adls_name}.dfs.core.windows.net"              = "OAuth",
      "fs.azure.account.oauth.provider.type.${module.datalake[0].adls_name}.dfs.core.windows.net"    = "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
      "fs.azure.account.oauth2.client.id.${module.datalake[0].adls_name}.dfs.core.windows.net"       = module.datalake[0].databricks_adls_app_id,
      "fs.azure.account.oauth2.client.secret.${module.datalake[0].adls_name}.dfs.core.windows.net"   = "{{secrets/${databricks_secret_scope.secrets.name}/${module.datalake[0].databricks_adls_app_secret_key}}}",
      "fs.azure.account.oauth2.client.endpoint.${module.datalake[0].adls_name}.dfs.core.windows.net" = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/token"
      "spark.secret.datalake-uri"                                                                    = "{{secrets/${databricks_secret_scope.secrets.name}/${module.datalake[0].databricks_adls_uri_secret_key}}}"
    }) : tomap({}),
    # Secrets for each data source
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
    }),
    # Additional secrets from the config
    tomap({ for secret_name, secret_value in var.transform.databricks_secrets :
      "spark.secret.${secret_name}" => "{{secrets/${databricks_secret_scope.secrets.name}/${secret_name}}}"
    }),
    local.unity_catalog_enabled ? tomap({
      "spark.secret.unity-catalog-catalog-name" = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.unity_catalog_catalog_name[0].key}}}"
      "spark.secret.unity-catalog-schema-name"  = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.unity_catalog_schema_name[0].key}}}"
    }) : tomap({}),
    # Any values set in the config
    var.transform.spark_config,
    # Special config if in single node configuration
    local.single_node ? tomap({
      "spark.databricks.cluster.profile" : "singleNode"
      "spark.master" : "local[*]"
    }) : tomap({})
  )

  dynamic "library" {
    for_each = var.transform.databricks_libraries.pypi
    content {
      pypi {
        package = library.value.package
        repo    = library.value.repo
      }
    }
  }

  dynamic "library" {
    for_each = var.transform.databricks_libraries.maven
    content {
      maven {
        coordinates = library.value.coordinates
        repo        = library.value.repo
        exclusions  = library.value.exclusions
      }
    }
  }

  dynamic "library" {
    for_each = var.transform.databricks_libraries.jar
    content {
      jar = library.value
    }
  }

  dynamic "init_scripts" {
    for_each = var.transform.databricks_cluster.init_scripts
    content {
      dbfs {
        destination = "dbfs:/${local.init_scripts_dir}/${basename(init_scripts.value)}"
      }
    }
  }

  cluster_log_conf {
    dbfs {
      destination = "dbfs:/${local.cluster_logs_dir}"
    }
  }

  spark_env_vars = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.transform.connection_string
  }

  custom_tags = local.single_node ? {
    "ResourceClass" = "SingleNode"
  } : {}

  depends_on = [time_sleep.wait_for_databricks_network]
}

resource "databricks_dbfs_file" "dbfs_init_script_upload" {
  for_each = toset(var.transform.databricks_cluster.init_scripts)
  # Source path on local filesystem
  source = each.key
  # Path on DBFS
  path = "/${local.init_scripts_dir}/${basename(each.key)}"

  depends_on = [time_sleep.wait_for_databricks_network]
}

# databricks secret scope, in-built. Not able to use key vault backed scope due to limitation in databricks:
# https://learn.microsoft.com/en-us/azure/databricks/security/secrets/secret-scopes#--create-an-azure-key-vault-backed-secret-scope-using-the-databricks-cli 
resource "databricks_secret_scope" "secrets" {
  name       = "flowehr-secrets"
  depends_on = [time_sleep.wait_for_databricks_network]
}

resource "databricks_service_principal" "adf_managed_identity_sp" {
  application_id = data.azuread_service_principal.adf_identity_sp.application_id
  display_name   = "ADF Service Principal for ${var.naming_suffix}"
}

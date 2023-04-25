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

data "databricks_spark_version" "latest_lts" {
  spark_version = var.transform.spark_version
  depends_on    = [time_sleep.wait_for_databricks_network]
}

data "databricks_node_type" "smallest" {
  # Providing no required configuration, Databricks will pick the smallest node possible
  depends_on = [time_sleep.wait_for_databricks_network]
}

# for prod - this will select something like E16ads v5 => ~$1.18ph whilst running
data "databricks_node_type" "prod" {
  min_memory_gb       = 128
  min_cores           = 16
  local_disk_min_size = 600
  category            = "Memory Optimized"
}

resource "databricks_cluster" "fixed_single_node" {
  cluster_name            = "Fixed Job Cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = var.accesses_real_data ? data.databricks_node_type.prod.id : data.databricks_node_type.smallest.id
  autotermination_minutes = 10

  spark_conf = merge(
    tomap({
      "spark.databricks.cluster.profile" = "singleNode"
      "spark.master"                     = "local[*]"
      # Secrets for Feature store
      # Formatted according to syntax for referencing secrets in Spark config:
      # https://learn.microsoft.com/en-us/azure/databricks/security/secrets/secrets
      "spark.secret.feature-store-app-id"     = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_spn_app_id.key}}}"
      "spark.secret.feature-store-app-secret" = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_spn_app_secret.key}}}"
      "spark.secret.feature-store-fqdn"       = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_fqdn.key}}}"
      "spark.secret.feature-store-database"   = "{{secrets/${databricks_secret_scope.secrets.name}/${databricks_secret.flowehr_databricks_sql_database.key}}}"
    }),
    # Secrets for each data source
    # Formatted according to syntax for referencing secrets in Spark config:
    # https://learn.microsoft.com/en-us/azure/databricks/security/secrets/secrets
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

  depends_on = [time_sleep.wait_for_databricks_network]
}

# databricks secret scope, in-built. Not able to use key vault backed scope due to limitation in databricks:
# https://learn.microsoft.com/en-us/azure/databricks/security/secrets/secret-scopes#--create-an-azure-key-vault-backed-secret-scope-using-the-databricks-cli 
resource "databricks_secret_scope" "secrets" {
  name       = "flowehr-secrets"
  depends_on = [time_sleep.wait_for_databricks_network]
}

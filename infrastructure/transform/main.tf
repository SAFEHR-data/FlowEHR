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
  spark_version = var.spark_version

  depends_on = [azurerm_databricks_workspace.databricks]
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

  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  depends_on = [
    azurerm_databricks_workspace.databricks,
    azurerm_private_endpoint.databricks_control_plane,
    azurerm_private_endpoint.databricks_filesystem
  ]
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

resource "azurerm_data_factory_linked_service_azure_databricks" "msi_linked" {
  name            = local.linked_service_name
  data_factory_id = azurerm_data_factory.adf.id
  description     = "Azure Databricks linked service via MSI"
  adb_domain      = "https://${azurerm_databricks_workspace.databricks.workspace_url}"

  msi_work_space_resource_id = azurerm_databricks_workspace.databricks.id
  existing_cluster_id        = databricks_cluster.fixed_single_node.cluster_id
}

resource "azurerm_data_factory_linked_service_key_vault" "msi_linked" {
  name            = "KVLinkedServiceViaMSI"
  data_factory_id = azurerm_data_factory.adf.id
  description     = "Key Vault linked service via MSI"
  key_vault_id    = var.core_kv_id
}

resource "azurerm_data_factory_pipeline" "pipeline" {
  name            = "databricks-pipeline-${var.naming_suffix}"
  data_factory_id = azurerm_data_factory.adf.id
  activities_json = jsonencode(
    [
      {
        "name" : "DatabricksPythonActivity",
        "type" : "DatabricksSparkPython",
        "typeProperties" : {
          "pythonFile" : "${local.python_file_dbfs_path}/${local.python_file_name}",
          "libraries" : [
            {
              "whl" : "${local.whl_file_dbfs_path}/${local.whl_file_name}"
            }
          ]
        },
        "linkedServiceName" : {
          "referenceName" : "${local.adb_linked_service_name}",
          "type" : "LinkedServiceReference"
        }
      }
    ]
  )
}

resource "databricks_dbfs_file" "dbfs_whl_file_upload" {
  source = "${local.whl_file_local_path}/${local.whl_file_name}"
  path   = "/${local.whl_file_name}"
}

resource "databricks_dbfs_file" "dbfs_pythong_file_upload" {
  source = "${local.python_file_local_path}/${local.python_file_name}"
  path   = "/${local.python_file_name}"
}

resource "azurerm_data_factory_trigger_schedule" "trigger" {
  name            = "databricks-pipeline-trigger-${var.naming_suffix}"
  data_factory_id = azurerm_data_factory.adf.id
  pipeline_name   = azurerm_data_factory_pipeline.pipeline.name
  interval        = 15
  frequency       = "Minute"
}

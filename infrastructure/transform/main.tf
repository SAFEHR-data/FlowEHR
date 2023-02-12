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
  name                        = "dbks-${var.naming_suffix}"
  resource_group_name         = var.core_rg_name
  managed_resource_group_name = "rg-dbks-${var.naming_suffix}"
  location                    = var.core_rg_location
  sku                         = "standard"
  tags                        = var.tags
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

  depends_on = [azurerm_databricks_workspace.databricks]
}

resource "azurerm_data_factory" "adf" {
  name                = "adf-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name


  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "adf_can_create_clusters" {
  scope                = azurerm_databricks_workspace.databricks.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

# Get all directories that have activities.json in them and say that they are pipeline directories
resource "azurerm_data_factory_pipeline" "pipeline" {
  for_each        = local.pipeline_dirs
  name            = "databricks-pipeline-${basename(each.value)}-${var.naming_suffix}"
  data_factory_id = azurerm_data_factory.adf.id
  activities_json = file("${each.value}/${local.activities_file}")
}

# Assuming that all artifacts will be built 
resource "databricks_dbfs_file" "dbfs_artifact_upload" {
  for_each = { for artifact in local.artifacts: artifact.artifact_path => artifact.pipeline}
  # Source path on local filesystem
  source   = each.key
  # Path on DBFS
  path     = "/pipelines/${each.value}/${local.artifacts_dir}/${basename(each.key)}"
}

resource "azurerm_data_factory_linked_service_azure_databricks" "msi_linked" {
  name            = "ADBLinkedServiceViaMSI"
  data_factory_id = azurerm_data_factory.adf.id
  description     = "Azure Databricks linked service via MSI"
  adb_domain      = "https://${azurerm_databricks_workspace.databricks.workspace_url}"

  msi_work_space_resource_id = azurerm_databricks_workspace.databricks.id

  existing_cluster_id = databricks_cluster.fixed_single_node.cluster_id
}

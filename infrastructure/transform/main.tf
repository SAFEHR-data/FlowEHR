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

resource "azurerm_role_assignment" "adf_can_create_clusters" {
  scope                = azurerm_databricks_workspace.databricks.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

resource "azurerm_data_factory" "adf" {
  name                = "adf-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_data_factory_pipeline" "pipeline" {
  name            = "databricks-pipeline-${var.naming_suffix}"
  data_factory_id = azurerm_data_factory.adf.id
  activities_json = <<JSON
[
  {
    "name": "DatabricksPythonActivity",
    "type": "DatabricksSparkPython",
    "typeProperties": {
        "pythonFile": "dbfs:/entrypoint.py",
        "libraries": [
            {
                "whl": "dbfs:/src-0.0.1-py3-none-any.whl"
            }
        ]
    },
    "linkedServiceName": {
        "referenceName": "ADBLinkedServiceViaMSI",
        "type": "LinkedServiceReference"
    }
  }
]
  JSON
}

resource "databricks_dbfs_file" "dbfs_file_upload" {
  source = "${var.whl_file_local_path}/${var.whl_file_name}"
  path   = "/${var.whl_file_name}"
}

resource "azurerm_data_factory_trigger_schedule" "trigger" {
  name            = "databricks-pipeline-trigger-${var.naming_suffix}"
  data_factory_id = azurerm_data_factory.adf.id
  pipeline_name   = azurerm_data_factory_pipeline.pipeline.name
  interval        = 5
  frequency       = "Minute"
}

resource "azurerm_data_factory_linked_service_azure_databricks" "msi_linked" {
  name            = "ADBLinkedServiceViaMSI"
  data_factory_id = azurerm_data_factory.adf.id
  description     = "Azure Databricks linked service via MSI"
  adb_domain      = "https://${azurerm_databricks_workspace.databricks.workspace_url}"

  msi_work_space_resource_id = azurerm_databricks_workspace.databricks.id

  existing_cluster_id = databricks_cluster.fixed_single_node.cluster_id
}

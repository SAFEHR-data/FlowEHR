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

resource "azurerm_data_factory_pipeline" "pipeline" {
  for_each        = { for pipeline in local.pipelines : pipeline.pipeline_dir => pipeline.pipeline_json }
  name            = each.value.name
  data_factory_id = azurerm_data_factory.adf.id
  activities_json = jsonencode(each.value.properties.activities)
  parameters      = { for param_name, param in each.value.properties.parameters : param_name => param.defaultValue }

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

  depends_on = [time_sleep.wait_for_databricks_network]
}

resource "azurerm_data_factory_trigger_tumbling_window" "pipeline_trigger" {
  for_each = { for trigger in local.triggers : trigger.pipeline => trigger.trigger if trigger != null }

  name            = "TumblingWindowTrigger${each.key}"
  data_factory_id = azurerm_data_factory.adf.id

  start_time      = each.value.properties.typeProperties.startTime
  end_time        = try(each.value.properties.typeProperties.endTime, null)
  delay           = try(each.value.properties.typeProperties.delay, null)
  max_concurrency = try(each.value.properties.typeProperties.maxConcurrency, null)
  frequency       = each.value.properties.typeProperties.frequency
  interval        = each.value.properties.typeProperties.interval

  retry {
    count    = try(each.value.properties.typeProperties.retryPolicy.count, null)
    interval = try(each.value.properties.typeProperties.retryPolicy.intervalInSeconds, null)
  }

  pipeline {
    name       = each.value.properties.pipeline.pipelineReference.referenceName
    parameters = each.value.properties.pipeline.parameters
  }

  # Trigger dependencies and additional properties aren't supported
  depends_on = [
    azurerm_data_factory_pipeline.pipeline
  ]
}

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

locals {
  sql_server_features_admin_username = "adminuser"
  sql_owner_app_name                 = "flowehr-sql-owner-${lower(var.naming_suffix)}"
  databricks_adls_app_name           = "flowehr-databricks-adls-${lower(var.naming_suffix)}"
  databricks_sql_app_name            = "flowehr-databricks-datawriter-${lower(var.naming_suffix)}"
  external_connection_app_name       = "flowehr-external-${lower(var.naming_suffix)}"
  pipeline_file                      = "pipeline.json"
  trigger_file                       = "trigger.json"
  artifacts_dir                      = "artifacts"
  init_scripts_dir                   = "init_scripts"
  cluster_logs_dir                   = "cluster_logs"
  adb_linked_service_name            = "ADBLinkedServiceViaMSI"
  dbfs_storage_account_name          = "dbfs${var.naming_suffix_truncated}"
  datalake_enabled                   = try(var.transform.datalake, null) != null
  unity_catalog_enabled              = try(var.transform.unity_catalog, null) != null
  create_unity_catalog_metastore = (
    local.unity_catalog_enabled
    && try(var.transform.unity_catalog_metastore.metastore_name, null) != null
  )

  autoscale_cluster = var.transform.databricks_cluster.autoscale != null
  single_node       = !local.autoscale_cluster && var.transform.databricks_cluster.num_of_workers == 0

  # IPs required for Databricks UDRs 
  # Built from https://learn.microsoft.com/en-us/azure/databricks/resources/supported-regions#--control-plane-nat-webapp-and-extended-infrastructure-ip-addresses-and-domains
  databricks_udr_ips = yamldecode(file("${path.module}/databricks-udr-ips.yaml"))
  databricks_service_tags = {
    "databricks" : "AzureDatabricks",
    "sql" : "Sql",
    "storage" : "Storage",
    "eventhub" : "EventHub"
  }

  all_pipeline_files = fileset(path.module, "../../transform/pipelines/**/${local.pipeline_file}")

  # Example value: [ "../../transform/pipelines/hello-world" ]
  paths = toset([
    for pipeline_file in local.all_pipeline_files : dirname(pipeline_file)
  ])

  pipelines = [
    for path in local.paths : {
      name = basename(path)
      path = path
      json = jsondecode(file("${path}/${local.pipeline_file}"))
    }
  ]

  # Example value: [ { "artifact_path" = "path/to/entrypoint.py", "pipeline" = "hello-world" } ]
  artifacts = flatten([
    for pipeline in local.pipelines : [
      for artifact in fileset("${pipeline.path}/${local.artifacts_dir}", "*") : {
        pipeline      = pipeline.name
        artifact_path = "${pipeline.path}/${local.artifacts_dir}/${artifact}"
      }
    ]
  ])

  triggers = flatten([
    for pipeline in local.pipelines : [
      fileexists("${pipeline.path}/${local.trigger_file}") ? {
        pipeline = pipeline.name
        trigger  = jsondecode(file("${pipeline.path}/${local.trigger_file}"))
      } : null
    ]
  ])

  data_source_connections_with_peerings = [
    for idx, item in var.data_source_connections : item if item.peering != null
  ]

  peerings = { for idx, item in local.data_source_connections_with_peerings :
    format("%s-%s", item.peering.virtual_network_name, item.peering.resource_group_name) => {
      virtual_network_name = item.peering.virtual_network_name
      resource_group_name  = item.peering.resource_group_name
    }
  }

  peered_vnet_ids = { for idx, item in data.azurerm_virtual_network.peered_data_source_networks :
    format("%s-%s", item.name, item.resource_group_name) => item.id
  }

  data_source_dns_zones = distinct(flatten([
    for idx, item in local.data_source_connections_with_peerings : [
      for idx, zone in item.peering.dns_zones : {
        name                = format("%s-%s", item.name, zone)
        dns_zone_name       = zone
        resource_group_name = item.peering.resource_group_name
      }
    ]
  ]))

  developers      = { "name" : var.developers_ad_group_display_name, "role" : "db_datareader" }
  data_scientists = { "name" : var.data_scientists_ad_group_display_name, "role" : "db_datareader" }
  apps            = { "name" : var.apps_ad_group_display_name, "role" : "db_datareader" }
  databricks_app  = { "name" : local.databricks_sql_app_name, "role" : "db_owner" }

  real_data_users_groups = [
    local.apps,
    local.data_scientists,
    local.databricks_app
  ]

  synth_data_users_groups = [
    local.apps,
    local.data_scientists,
    local.databricks_app,
    local.developers
  ]

  sql_users_to_create = var.accesses_real_data ? local.real_data_users_groups : local.synth_data_users_groups

  predefined_metric_name = "rows_updated"
}

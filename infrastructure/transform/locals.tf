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
  databricks_app_name                = "flowehr-databricks-datawriter-${lower(var.naming_suffix)}"
  pipeline_file                      = "pipeline.json"
  trigger_file                       = "trigger.json"
  artifacts_dir                      = "artifacts"
  adb_linked_service_name            = "ADBLinkedServiceViaMSI"
  dbfs_storage_account_name          = "dbfs${var.naming_suffix_truncated}"

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
  pipeline_dirs = toset([
    for pipeline_file in local.all_pipeline_files : dirname(pipeline_file)
  ])

  pipelines = [
    for pipeline_dir in local.pipeline_dirs : {
      pipeline_dir  = pipeline_dir
      pipeline_json = jsondecode(file("${pipeline_dir}/${local.pipeline_file}"))
    }
  ]

  # Example value: [ { "artifact_path" = "path/to/entrypoint.py", "pipeline" = "hello-world" } ]
  artifacts = flatten([
    for pipeline_dir in local.pipeline_dirs : [
      for artifact in fileset("${pipeline_dir}/${local.artifacts_dir}", "*") : {
        artifact_path = "${pipeline_dir}/${local.artifacts_dir}/${artifact}"
        pipeline      = basename(pipeline_dir)
      }
    ]
  ])

  triggers = flatten([
    for pipeline_dir in local.pipeline_dirs : [
      fileexists("${pipeline_dir}/${local.trigger_file}") ? {
        pipeline = basename(pipeline_dir)
        trigger  = jsondecode(file("${pipeline_dir}/${local.trigger_file}"))
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
  apps            = { "name" : azuread_group.ad_group_apps.display_name, "role" : "db_datareader" }
  databricks_app  = { "name" : local.databricks_app_name, "role" : "db_owner" }

  real_data_users_groups = [
    local.data_scientists,
    local.apps,
    local.databricks_app
  ]

  synth_data_users_groups = [
    local.data_scientists,
    local.apps,
    local.databricks_app,
    local.developers
  ]

  sql_users_to_create = var.accesses_real_data ? local.real_data_users_groups : local.synth_data_users_groups
}

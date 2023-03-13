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

# Create Azure Data Lake Gen2 store with bronze, silver and gold folders
resource "azurerm_storage_account" "adls" {
  name                     = "adls${replace(lower(var.naming_suffix), "-", "")}"
  resource_group_name      = var.core_rg_name
  location                 = var.core_rg_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "adls_bronze" {
  name               = "bronze"
  storage_account_id = azurerm_storage_account.adls.id

  ace {
    type        = "user"
    scope       = "access"
    id          = azuread_application.flowehr_databricks_adls.object_id
    permissions = "--x"
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "adls_silver" {
  name               = "silver"
  storage_account_id = azurerm_storage_account.adls.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "adls_gold" {
  name               = "gold"
  storage_account_id = azurerm_storage_account.adls.id
}

# Create path for raw data in bronze filesystem
resource "azurerm_storage_data_lake_gen2_path" "adls_bronze_raw" {
  path               = "raw"
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.adls_bronze.name
  storage_account_id = azurerm_storage_account.adls.id
  resource           = "directory"

  ace {
    type        = "user"
    scope       = "access"
    id          = azuread_application.flowehr_databricks_adls.object_id
    permissions = "rwx"
  }
}

# optional firewall rule when running in local_mode
resource "azurerm_storage_account_network_rules" "adls" {
  storage_account_id = azurerm_storage_account.adls.id
  default_action     = "Deny"
  ip_rules           = var.local_mode == true ? [var.deployer_ip_address] : []
}


# Private DNS and endpoint for ADLS Gen2
resource "azurerm_private_dns_zone" "adls" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = var.core_rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "adls" {
  name                  = "vnl-adls-${var.naming_suffix}"
  resource_group_name   = var.core_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.adls.name
  virtual_network_id    = data.azurerm_virtual_network.core.id
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "adls" {
  name                = "adls-datalake-${lower(var.naming_suffix)}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  subnet_id           = var.core_subnet_id

  private_service_connection {
    name                           = "adls-datalake-${lower(var.naming_suffix)}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.adls.id
    subresource_names              = ["dfs"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-adls-${var.naming_suffix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.adls.id]
  }
}


# AAD App + SPN for Databricks -> ADLS Access
resource "azuread_application" "flowehr_databricks_adls" {
  display_name = local.databricks_app_name
  owners       = [data.azurerm_client_config.current.object_id]
}
resource "azuread_application_password" "flowehr_databricks_adls" {
  application_object_id = azuread_application.flowehr_databricks_adls.object_id
}
resource "azuread_service_principal" "flowehr_databricks_adls" {
  application_id = azuread_application.flowehr_databricks_adls.application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

resource "azurerm_key_vault_secret" "flowehr_databricks_adls_spn_app_id" {
  name         = "flowehr-dbks-adls-app-id"
  value        = azuread_service_principal.flowehr_databricks_adls.application_id
  key_vault_id = var.core_kv_id
}
resource "azurerm_key_vault_secret" "flowehr_databricks_adls_spn_app_secret" {
  name         = "flowehr-dbks-adls-app-secret"
  value        = azuread_application_password.flowehr_databricks_adls.value
  key_vault_id = var.core_kv_id
}

# grant Databricks SPN access to ADLS Gen2
resource "azurerm_role_assignment" "flowehr_databricks_adls" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.flowehr_databricks_adls.object_id
}

resource "databricks_mount" "adls_bronze" {
  name       = "adls-data-lake-bronze"
  uri        = "abfss://${azurerm_storage_data_lake_gen2_filesystem.adls_bronze.name}@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
  cluster_id = databricks_cluster.fixed_single_node.cluster_id
  extra_configs = {
    "fs.azure.account.auth.type" : "OAuth",
    "fs.azure.account.oauth.provider.type" : "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "fs.azure.account.oauth2.client.id" : azuread_application.flowehr_databricks_adls.application_id,
    "fs.azure.account.oauth2.client.secret" : "{{secrets/${databricks_secret_scope.secrets.name}/${azurerm_key_vault_secret.flowehr_databricks_adls_spn_app_secret.name}}}",
    "fs.azure.account.oauth2.client.endpoint" : "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/token",
    "fs.azure.createRemoteFileSystemDuringInitialization" : "false",
  }

  depends_on = [
    azurerm_role_assignment.flowehr_databricks_adls,
    azurerm_private_endpoint.adls,
    azurerm_storage_account_network_rules.adls
  ]
}

# Create Azure Data Factory linked service to ADLS Gen2
resource "azurerm_role_assignment" "adf_can_access_adls" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "adls" {
  name                 = "ADLSLinkedServiceViaMSI"
  data_factory_id      = azurerm_data_factory.adf.id
  description          = "ADLS Gen2"
  use_managed_identity = true
  url                  = "https://${azurerm_storage_account.adls.name}.dfs.core.windows.net"
}


# # Add ADLS Gen2 as external location
# resource "databricks_service_principal" "deployer_sp" {
#   application_id = data.azurerm_client_config.current.client_id
# }

# resource "databricks_permission_assignment" "add_admin_spn" {
#   principal_id = databricks_service_principal.deployer_sp.id
#   permissions  = ["ADMIN"]
# }


# resource "databricks_metastore" "adls" {
#   name = "primary"
#   storage_root = "abfss://${azurerm_storage_data_lake_gen2_filesystem.adls_bronze.name}@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
#   owner         = azuread_application.flowehr_databricks_adls.application_id
#   force_destroy = false
# }

# resource "databricks_metastore_assignment" "adls" {
#   metastore_id = databricks_metastore.adls.id
#   workspace_id = azurerm_databricks_workspace.databricks.workspace_id
# }

# resource "databricks_storage_credential" "adls" {
#   name = "adls-datalake-cred"
#   azure_service_principal {
#     directory_id   = data.azurerm_client_config.current.tenant_id
#     application_id = azuread_application.flowehr_databricks_adls.application_id
#     client_secret  = azuread_application_password.flowehr_databricks_adls.value
#   }
# }

# resource "databricks_external_location" "adls_bronze" {
#   name = "adls-data-lake-bronze"
#   url  = "abfss://${azurerm_storage_data_lake_gen2_filesystem.adls_bronze.name}@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
#   credential_name = databricks_storage_credential.adls.name
# }

# resource "databricks_grants" "adls_bronze" {
#   external_location = databricks_external_location.adls_bronze.id
#   grant {
#     principal  = "Data Engineers"
#     privileges = ["CREATE_TABLE", "READ_FILES"]
#   }
# }

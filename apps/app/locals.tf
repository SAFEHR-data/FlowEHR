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
  feature_store_odbc = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:${data.azurerm_mssql_server.feature_store.fully_qualified_domain_name},1433;Database=${var.feature_store_db_name};Authentication=ActiveDirectoryMsi;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
  acr_repository     = var.app_id
  create_repo        = var.app_config.managed_repo != null
  core_gh_env        = var.environment
  staging_gh_env     = var.app_config.add_staging_slot ? "${var.environment}-testing-slot" : null
  branches_and_envs = var.app_config.add_staging_slot ? {
    "${var.environment}"              = local.core_gh_env
    "${var.environment}-testing-slot" = local.staging_gh_env
  } : { var.environment = local.core_gh_env }
  site_credential_name     = var.app_config.add_staging_slot ? azurerm_linux_web_app_slot.staging[0].site_credential[0].name : azurerm_linux_web_app.app.site_credential[0].name
  site_credential_password = var.app_config.add_staging_slot ? azurerm_linux_web_app_slot.staging[0].site_credential[0].password : azurerm_linux_web_app.app.site_credential[0].password
}

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
  app_id_truncated       = substr(replace(replace(var.app_id, "_", ""), "-", ""), 0, 17)
  github_repository_name = var.app_id
  acr_repository         = var.app_id

  feature_store_odbc = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:${data.azurerm_mssql_server.feature_store.fully_qualified_domain_name},1433;Database=${var.feature_store_db_name};Authentication=ActiveDirectoryMsi;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
  create_repo        = var.app_config.managed_repo != null

  core_gh_env         = var.environment
  core_branch_name    = local.core_gh_env
  testing_gh_env      = var.app_config.add_testing_slot ? "${var.environment}-testing_slot" : null
  testing_branch_name = local.testing_gh_env

  webapp_name              = "webapp-${replace(var.app_id, "_", "-")}-${var.naming_suffix}"
  testing_slot_name        = "testing"
  testing_slot_webapp_name = "${local.webapp_name}-${local.testing_slot_name}"

  # List webapp names (main and slots) that require auth to be enabled
  auth_webapp_names = (
    var.app_config.require_auth
    ? (
      var.app_config.add_testing_slot
      ? toset([local.webapp_name, local.testing_slot_webapp_name])
      : toset([local.webapp_name])
    )
    : toset([])
  )

  # Map deployment branch and github environment names for main & testing slot (if enabled)
  branches_and_envs = var.app_config.add_testing_slot ? {
    "${local.core_branch_name}"    = local.core_gh_env
    "${local.testing_branch_name}" = local.testing_gh_env
  } : { "${local.core_branch_name}" = local.core_gh_env }

  acr_deploy_reusable_workflow_filename = "acr_deploy_reusable.yml"
  slot_swap_reusable_workflow_filename  = "slot_swap_reusable.yml"

  # Map GitHub/FlowEHR environments and corresponding GH workflow files to deploy to them
  envs_and_workflow_templates = var.app_config.add_testing_slot ? {
    "${local.core_gh_env}"    = data.template_file.core_github_workflow
    "${local.testing_gh_env}" = data.template_file.testing_github_workflow[0]
  } : { "${local.core_gh_env}" = data.template_file.core_github_workflow }

  site_credential_name     = azurerm_linux_web_app.app.site_credential[0].name
  site_credential_password = azurerm_linux_web_app.app.site_credential[0].password
}

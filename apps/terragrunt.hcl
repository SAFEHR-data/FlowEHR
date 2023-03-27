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

include "root" {
  path = find_in_parent_folders()
}

locals {
  providers            = read_terragrunt_config("${get_repo_root()}/providers.hcl")
  configuration        = read_terragrunt_config("${get_repo_root()}/configuration.hcl")
  merged_root_config   = local.configuration.locals.merged_root_config

  # Get GitHub App PEM cert as string - first try local file otherwise look for env var
  github_app_cert_path = "${get_terragrunt_dir()}/github.pem"
  github_app_cert      = fileexists(local.github_app_cert_path) ? file(local.github_app_cert_path) : get_env("GH_APP_CERT", "")

  # Get app configuration from apps.yaml and app.{ENVIRONMENT}.yaml
  apps_config_path     = "${get_terragrunt_dir()}/apps.yaml"
  apps_config          = fileexists(local.apps_config_path) ? yamldecode(file(local.apps_config_path)) : null
  apps_env_config_path = "${get_terragrunt_dir()}/apps.${get_env("ENVIRONMENT", "local")}.yaml"
  apps_env_config      = fileexists(local.apps_env_config_path) ? yamldecode(file(local.apps_env_config_path)) : null

  merged_apps_config = {
    # As it's a map, we need to iterate as direct merge() would overwrite each key's value entirely
    for app_id, app_config in local.apps_env_config : app_id =>
      # And we don't want apps defined in apps.yaml but not in current {ENVIRONMENT} file to be deployed,
      # so only merge if key exists with env-specific config taking precedence
      merge(local.apps_config[app_id], app_config)
  }
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "${local.providers.locals.terraform_version}"

  required_providers {
    ${local.providers.locals.required_provider_azure}
    ${local.providers.locals.required_provider_github}
  }
}
EOF
}

# Child module also needs GH required provider reference due to provider inheritance bug:
# https://github.com/integrations/terraform-provider-github/issues/876
generate "child_terraform" {
  path      = "app/terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    ${local.providers.locals.required_provider_github}
    ${local.providers.locals.required_provider_external}
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
${local.providers.locals.azure_provider}

provider "github" {
  owner = var.serve.github_owner
  app_auth {
    id              = var.serve.github_app_id
    installation_id = var.serve.github_app_installation_id
    pem_file        = var.github_app_cert
  }
}
EOF
}

dependency "core" {
  config_path = "${get_repo_root()}/infrastructure/core"

  mock_outputs = {
    core_rg_name            = "core_rg_name"
    core_rg_location        = "core_rg_location"
    core_kv_id              = "core_kv_id"
    core_log_analytics_name = "core_log_analytics_name"
  }
  mock_outputs_allowed_terraform_commands = ["destroy"]
}

dependency "transform" {
  config_path = "${get_repo_root()}/infrastructure/transform"

  mock_outputs = {
    feature_store_server_name        = "transform_feature_store_server_name"
    feature_store_db_name            = "transform_feature_store_db_name"
    apps_ad_group_display_name       = "transform_apps_ad_group_display_name"
    developers_ad_group_display_name = "transform_developers_ad_group_display_name"
    apps_ad_group_principal_id       = "transform_apps_ad_group_principal_id"
    developers_ad_group_principal_id = "transform_developers_ad_group_principal_id"
  }
  mock_outputs_allowed_terraform_commands = ["destroy"]
}

dependency "serve" {
  config_path = "${get_repo_root()}/infrastructure/serve"

  mock_outputs = {
    app_service_plan_name = "serve_app_service_plan_name"
    acr_name              = "serve_acr_name"
    cosmos_account_name   = "serve_cosmos_account_name"
    webapps_subnet_id     = "serve_webapps_subnet_id"
  }
  mock_outputs_allowed_terraform_commands = ["destroy"]
}

inputs = {
  core_rg_name            = dependency.core.outputs.core_rg_name
  core_rg_location        = dependency.core.outputs.core_rg_location
  core_kv_id              = dependency.core.outputs.core_kv_id
  core_log_analytics_name = dependency.core.outputs.core_log_analytics_name

  transform_feature_store_server_name        = dependency.transform.outputs.feature_store_server_name
  transform_feature_store_db_name            = dependency.transform.outputs.feature_store_db_name
  transform_apps_ad_group_display_name       = dependency.transform.outputs.apps_ad_group_display_name
  transform_developers_ad_group_display_name = dependency.transform.outputs.developers_ad_group_display_name
  transform_apps_ad_group_principal_id       = dependency.transform.outputs.apps_ad_group_principal_id
  transform_developers_ad_group_principal_id = dependency.transform.outputs.developers_ad_group_principal_id

  serve_app_service_plan_name = dependency.serve.outputs.app_service_plan_name
  serve_acr_name              = dependency.serve.outputs.acr_name
  serve_cosmos_account_name   = dependency.serve.outputs.cosmos_account_name
  serve_webapps_subnet_id     = dependency.serve.outputs.webapps_subnet_id

  github_app_cert = local.github_app_cert
  apps            = local.merged_apps_config
}

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

include "shared" {
  path = "${get_repo_root()}/shared.hcl"
}

locals {
  providers = read_terragrunt_config("${get_repo_root()}/providers.hcl")

  # Get GitHub App PEM cert as string - first try local file otherwise look for env var
  github_app_cert_path = "${get_terragrunt_dir()}/github.pem"
  github_app_cert      = fileexists(local.github_app_cert_path) ? file(local.github_app_cert_path) : get_env("GH_APP_CERT", "")

  # Get shared app configuration (apps.yaml) and environment-specific config (app.{ENVIRONMENT}.yaml)
  shared_apps_config_path = "${get_terragrunt_dir()}/apps.yaml"
  env_apps_config_path    = "${get_terragrunt_dir()}/apps.${get_env("ENVIRONMENT", "local")}.yaml"
  shared_apps_config      = fileexists(local.shared_apps_config_path) ? tomap(yamldecode(file(local.shared_apps_config_path))) : tomap({})
  env_apps_config         = fileexists(local.env_apps_config_path) ? tomap(yamldecode(file(local.env_apps_config_path))) : tomap({})

  merged_apps_config = {
    # As it's a map, we need to iterate as direct merge() would overwrite each key's value entirely
    for app_id, env_app_config in local.env_apps_config : app_id =>
    # And we don't want apps defined in apps.yaml but not in current {ENVIRONMENT} file to be deployed,
    # so only merge if key exists with env-specific config taking precedence
    merge(try(local.shared_apps_config[app_id], null), env_app_config)
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
    ${local.providers.locals.required_provider_null}
    ${local.providers.locals.required_provider_external}
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
  required_version = "${local.providers.locals.terraform_version}"

  required_providers {
    ${local.providers.locals.required_provider_github}
    ${local.providers.locals.required_provider_external}
    ${local.providers.locals.required_provider_random}
    ${local.providers.locals.required_provider_azure}
    ${local.providers.locals.required_provider_azuread}
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
    naming_suffix                         = "naming_suffix"
    naming_suffix_truncated               = "naming_suffix_truncated"
    core_rg_name                          = "core_rg_name"
    core_rg_location                      = "core_rg_location"
    core_kv_id                            = "core_kv_id"
    core_log_analytics_name               = "core_log_analytics_name"
    webapps_subnet_id                     = "serve_webapps_subnet_id"
    developers_ad_group_principal_id      = "core_developers_ad_group_principal_id"
    data_scientists_ad_group_principal_id = "core_data_scientists_ad_group_principal_id"
  }
  mock_outputs_allowed_terraform_commands = ["init", "destroy", "validate"]
}

dependency "transform" {
  config_path = "${get_repo_root()}/infrastructure/transform"

  mock_outputs = {
    feature_store_server_name  = "transform_feature_store_server_name"
    feature_store_db_name      = "transform_feature_store_db_name"
    apps_ad_group_principal_id = "transform_apps_ad_group_principal_id"
  }
  mock_outputs_allowed_terraform_commands = ["init", "destroy", "validate"]
}

dependency "serve" {
  config_path = "${get_repo_root()}/infrastructure/serve"

  mock_outputs = {
    app_service_plan_name = "serve_app_service_plan_name"
    acr_name              = "serve_acr_name"
    cosmos_account_name   = "serve_cosmos_account_name"
  }
  mock_outputs_allowed_terraform_commands = ["init", "destroy", "validate"]
}

inputs = {
  naming_suffix                              = dependency.core.outputs.naming_suffix
  naming_suffix_truncated                    = dependency.core.outputs.naming_suffix_truncated
  core_rg_name                               = dependency.core.outputs.core_rg_name
  core_rg_location                           = dependency.core.outputs.core_rg_location
  core_kv_id                                 = dependency.core.outputs.core_kv_id
  core_log_analytics_name                    = dependency.core.outputs.core_log_analytics_name
  serve_webapps_subnet_id                    = dependency.core.outputs.webapps_subnet_id
  core_developers_ad_group_principal_id      = dependency.core.outputs.developers_ad_group_principal_id
  core_data_scientists_ad_group_principal_id = dependency.core.outputs.data_scientists_ad_group_principal_id

  transform_feature_store_server_name  = dependency.transform.outputs.feature_store_server_name
  transform_feature_store_db_name      = dependency.transform.outputs.feature_store_db_name
  transform_apps_ad_group_principal_id = dependency.transform.outputs.apps_ad_group_principal_id

  serve_app_service_plan_name = dependency.serve.outputs.app_service_plan_name
  serve_acr_name              = dependency.serve.outputs.acr_name
  serve_cosmos_account_name   = dependency.serve.outputs.cosmos_account_name

  github_app_cert = local.github_app_cert
  apps            = local.merged_apps_config
  suffix_override = get_env("SUFFIX_OVERRIDE", "")
}

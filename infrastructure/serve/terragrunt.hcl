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
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "${local.providers.locals.terraform_version}"

  required_providers {
    ${local.providers.locals.required_provider_azure}
    ${local.providers.locals.required_provider_null}
    ${local.providers.locals.required_provider_external}
    ${local.providers.locals.required_provider_time}
    ${local.providers.locals.required_provider_local}
    ${local.providers.locals.required_provider_azapi}
  }
}
EOF
}

dependency "core" {
  config_path = "../core"

  mock_outputs = {
    naming_suffix               = "naming_suffix"
    naming_suffix_truncated     = "naming_suffix_truncated"
    core_rg_name                = "core_rg_name"
    core_rg_location            = "core_rg_location"
    core_subnet_id              = "core_subnet_id"
    serve_webapps_address_space = "serve_webapps_address_space"
    private_dns_zones           = "private_dns_zones"
    aml_address_space           = "aml_address_space"

    algorithm_stewards_ad_group_principal_id = "algorithm_stewards_ad_group_principal_id"
  }
  mock_outputs_allowed_terraform_commands = ["init", "destroy", "validate"]
}

inputs = {
  naming_suffix                            = dependency.core.outputs.naming_suffix
  naming_suffix_truncated                  = dependency.core.outputs.naming_suffix_truncated
  core_rg_name                             = dependency.core.outputs.core_rg_name
  core_rg_location                         = dependency.core.outputs.core_rg_location
  core_subnet_id                           = dependency.core.outputs.core_subnet_id
  private_dns_zones                        = dependency.core.outputs.private_dns_zones
  algorithm_stewards_ad_group_principal_id = dependency.core.outputs.algorithm_stewards_ad_group_principal_id
}

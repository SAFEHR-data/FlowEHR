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
  # Root config from config.yaml
  root_config = yamldecode(file("${get_repo_root()}/config.yaml"))

  # Environment-specific config for current environment with config.{ENVIRONMENT}.yaml format
  env_config_path = "${get_repo_root()}/config.${get_env("ENVIRONMENT", "local")}.yaml"
  env_config      = fileexists(local.env_config_path) ? yamldecode(file(local.env_config_path)) : null

  # Merged configuration (with environment-specific config values overwriting root values)
  merged_root_config = merge(local.root_config, local.env_config)
}

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

resource "github_repository" "app" {
  name        = var.app_id
  description = var.app_config.description
  visibility  = "private"

  template {
    owner      = "UCLH-Foundry"
    repository = var.managed_repo.template
  }
}

resource "github_actions_secret" "example_secret" {
  repository      = "example_repository"
  secret_name     = "ACR_REPOSITORY_TOKEN"
  plaintext_value = var.some_secret_string
}

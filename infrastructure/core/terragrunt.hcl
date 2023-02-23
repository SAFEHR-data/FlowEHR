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

inputs = {
   # Additional variables are required for the build agent deployment
  devcontainer_acr_name = get_env("DEVCONTAINER_ACR_NAME", "")
  devcontainer_image_name = get_env("DEVCONTAINER_IMAGE_IMAGE", "")
  devcontainer_tag = get_env("DEVCONTAINER_TAG", "")
  github_runner_name = get_env("GITHUB_RUNNER_NAME", "")
  github_runner_token = get_env("GITHUB_RUNNER_TOKEN", "")
  github_repository = get_env("GITHUB_REPOSITORY", "")
}

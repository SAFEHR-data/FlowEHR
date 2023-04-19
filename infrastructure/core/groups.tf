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

resource "azuread_group" "ad_group_developers" {
  count            = var.accesses_real_data ? 0 : 1
  display_name     = "${local.naming_suffix} flowehr-developers"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true
}

resource "azuread_group" "ad_group_data_scientists" {
  count            = var.accesses_real_data ? 0 : 1
  display_name     = "${local.naming_suffix} flowehr-data-scientists"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true
}

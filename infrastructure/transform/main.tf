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

resource "azurerm_databricks_workspace" "transform" {
  name                        = "${var.naming_prefix}-dbks"
  resource_group_name         = var.core_rg_name
  managed_resource_group_name = "${var.naming_prefix}-rg-dbks"
  location                    = var.core_rg_location
  sku                         = "standard"
  tags                        = var.tags
}

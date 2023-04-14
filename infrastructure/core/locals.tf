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
  naming_suffix           = var.suffix_override == "" ? "${var.flowehr_id}-${var.environment}" : var.suffix_override
  naming_suffix_truncated = substr(replace(replace(local.naming_suffix, "-", ""), "_", ""), 0, 17)

  # Split the /24 (or larger) address space into subnets of required sizes
  # for the different terraform modules/required delegations. Databricks requires > /27
  address_space_is_slash24 = length(regexall("\\/24", azurerm_virtual_network.core.address_space[0])) > 0
  databricks_newbits       = local.address_space_is_slash24 ? 2 : 3
  other_newbits            = local.address_space_is_slash24 ? 4 : 3

  subnet_address_spaces = cidrsubnets(
    azurerm_virtual_network.core.address_space[0],
    3,
    local.databricks_newbits,
    local.databricks_newbits,
    3,
    local.other_newbits,
    local.other_newbits
  )
  core_shared_address_space          = local.subnet_address_spaces[0]
  databricks_host_address_space      = local.subnet_address_spaces[1]
  databricks_container_address_space = local.subnet_address_spaces[2]
  serve_webapps_address_space        = local.subnet_address_spaces[3]
  aml_address_space                  = local.subnet_address_spaces[4]
  # free_address_space               = local.subnet_address_spaces[5]

  required_private_dns_zones = {
    blob       = "privatelink.blob.core.windows.net"
    keyvault   = "privatelink.vaultcore.azure.net"
    cosmos     = "privatelink.documents.azure.com"
    databricks = "privatelink.azuredatabricks.net"
    sql        = "privatelink.database.windows.net"
  }
}

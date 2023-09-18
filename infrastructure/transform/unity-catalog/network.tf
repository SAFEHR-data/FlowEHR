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

resource "azurerm_private_endpoint" "metastore_storage" {
  name                = "pe-uc-${var.naming_suffix}"
  location            = data.azurerm_resource_group.core_rg.location
  resource_group_name = var.core_rg_name
  subnet_id           = data.azurerm_subnet.shared_subnet.id

  private_service_connection {
    name                           = "uc-blob-${var.naming_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = data.azurerm_storage_account.metastore_storage_account.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob-${var.naming_suffix}"
    private_dns_zone_ids = [var.private_dns_zones["blob"].id]
  }
}

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
  address_space = (
    var.use_random_address_space
    ? "10.${random_integer.ip1.value}.${random_integer.ip2.value}.0/24"
    : var.core_address_space
  )
  subnet_address_spaces = cidrsubnets(local.address_space, 2, 2, 2, 2)
}

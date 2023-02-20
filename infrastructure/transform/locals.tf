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
  storage_account_name    = "dbfs${var.truncated_naming_suffix}"
  adb_linked_service_name = "ADBLinkedServiceViaMSI"

  python_file_local_path = "../../transform/features"
  python_file_dbfs_path  = "dbfs:"
  python_file_name       = "entrypoint.py"

  whl_file_local_path = "../../transform/features/dist"
  whl_file_dbfs_path  = "dbfs:"
  whl_file_name       = "src-0.0.1-py3-none-any.whl"
}
